package main

import (
	"database/sql"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"
	"time"

	_ "github.com/lib/pq" // As suggested by lib/pq driver
	yaml "gopkg.in/yaml.v2"
)

// Environment needed/used
// PG_PASS: set postgres password
// GHA2DB_PATH: path to cncf/devstats repo
// REPOS_DIR: path where all repos (format 'org/repo') will be cloned and/or pulled

// AllProjects contain all projects data
type AllProjects struct {
	Projects map[string]Project `yaml:"projects"`
}

// Project contain mapping from project name to its command line used to sync it
type Project struct {
	PDB      string `yaml:"psql_db"`
	Disabled bool   `yaml:"disabled"`
}

func processOrg(org string, repos []string) (okRepos []string) {
	// Go to main repos directory
	wd := os.Getenv("REPOS_DIR")
	err := os.Chdir(wd)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %+v\n", err)
		return
	}

	// Go to current 'org' subdirectory
	wd += org
	err = os.Chdir(wd)
	if err != nil {
		// Try to Mkdir it if not exists
		err := os.Mkdir(wd, 0755)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %+v\n", err)
			return
		}
		err = os.Chdir(wd)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %+v\n", err)
			return
		}
	}

	// Iterate org's repositories
	for _, orgRepo := range repos {
		// Must be in org directory for every repo call
		err = os.Chdir(wd)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %+v\n", err)
			return
		}
		ary := strings.Split(orgRepo, "/")
		repo := ary[1]
		rwd := wd + "/" + repo
		err = os.Chdir(rwd)
		if err != nil {
			// We need to clone repo
			fmt.Printf("Cloning %s\n", orgRepo)
			cmd := exec.Command("git", "clone", "https://github.com/"+orgRepo+".git")
			cmd.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0")
			output, err := cmd.CombinedOutput()
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error git-clone: %s: %+v\n%s\n", orgRepo, err, string(output))
			} else {
				pwd, _ := os.Getwd()
				fmt.Printf("Cloned %s in %s\n", orgRepo, pwd)
				okRepos = append(okRepos, orgRepo)
			}
		} else {
			// We *may* need to pull repo
			fmt.Printf("Pulling %s\n", orgRepo)
			cmd := exec.Command("git", "reset", "--hard")
			cmd.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0")
			output, err := cmd.CombinedOutput()
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error git-reset: %s: %+v\n%s\n", orgRepo, err, string(output))
			}
			cmd = exec.Command("git", "pull")
			cmd.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0")
			output, err = cmd.CombinedOutput()
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error git-pull: %s: %+v\n%s\n", orgRepo, err, string(output))
			} else {
				pwd, _ := os.Getwd()
				fmt.Printf("Pulled %s in %s\n", orgRepo, pwd)
				okRepos = append(okRepos, orgRepo)
			}
		}
	}
	return
}

// pullRepos does all the job
func pullRepos() error {
	if os.Getenv("REPOS_DIR") == "" {
		return fmt.Errorf("you have to set environemnt variable REPOS_DIR to run this program")
	}

	// Read projects defined in `cncf/devstats`'s projects.yaml
	data, err := ioutil.ReadFile(os.Getenv("GHA2DB_PATH") + "projects.yaml")
	if err != nil {
		return err
	}
	var projects AllProjects
	err = yaml.Unmarshal(data, &projects)
	if err != nil {
		return err
	}
	dbs := make(map[string]bool)
	for _, proj := range projects.Projects {
		if proj.Disabled {
			continue
		}
		dbs[proj.PDB] = true
	}

	allRepos := make(map[string][]string)
	for db := range dbs {
		// Connect to Postgres `devstats` database.
		connectionString := "client_encoding=UTF8 sslmode='disable' host='127.0.0.1' port=5432 dbname='" + db + "' user='gha_admin' password='" + os.Getenv("PG_PASS") + "'"
		con, err := sql.Open("postgres", connectionString)
		if err != nil {
			return err
		}
		// Get list of orgs in a given database
		rows, err := con.Query("select distinct name from gha_repos where name like '%/%'")
		if err != nil {
			con.Close()
			return err
		}
		var (
			repo  string
			repos []string
		)
		for rows.Next() {
			err := rows.Scan(&repo)
			if err != nil {
				rows.Close()
				con.Close()
				return err
			}
			repos = append(repos, repo)
		}
		err = rows.Err()
		rows.Close()
		con.Close()
		if err != nil {
			return err
		}
		// Create map of distinct "org" --> list of repos
		for _, repo := range repos {
			ary := strings.Split(repo, "/")
			if len(ary) != 2 {
				return fmt.Errorf("invalid repo name: %s", repo)
			}
			org := ary[0]
			_, ok := allRepos[org]
			if !ok {
				allRepos[org] = []string{}
			}
			ary = append(allRepos[org], repo)
			allRepos[org] = ary
		}
	}

	// Process all orgs
	finalCmd := "./all_repos_log.sh "
	allOkRepos := []string{}
	for org, repos := range allRepos {
		okRepos := processOrg(org, repos)
		for _, okRepo := range okRepos {
			allOkRepos = append(allOkRepos, okRepo)
		}
		finalCmd += os.Getenv("REPOS_DIR") + org + "/* "
	}
	allOkReposStr := "["
	for _, okRepo := range allOkRepos {
		allOkReposStr += "  '" + okRepo + "',\n"
	}
	allOkReposStr += "]"
	fmt.Printf("AllRepos:\n%s\n", allOkReposStr)
	fmt.Printf("Final command:\n%s\n", finalCmd)
	return nil
}

func main() {
	dtStart := time.Now()
	err := pullRepos()
	dtEnd := time.Now()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %+v\n", err)
		return
	}
	fmt.Printf("All repos pulled in: %v\n", dtEnd.Sub(dtStart))
}
