package main

import (
	"database/sql"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
	"time"

	_ "github.com/lib/pq" // As suggested by lib/pq driver
	yaml "gopkg.in/yaml.v2"
)

// AllProjects contain all projects data
type AllProjects struct {
	Projects map[string]Project `yaml:"projects"`
}

// Project contain mapping from project name to its command line used to sync it
type Project struct {
	PDB      string `yaml:"psql_db"`
	Disabled bool   `yaml:"disabled"`
}

// pullRepos does all the job
// Environment needed/used
// PG_PASS: set postgres password
// GHA2DB_PATH: path to cncf/devstats repo
func pullRepos() error {
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
	fmt.Printf("AllRepos: %+v\n", allRepos)
	return nil
}

func main() {
	dtStart := time.Now()
	err := pullRepos()
	dtEnd := time.Now()
	if err != nil {
		fmt.Printf("Error: %+v\n", err)
		return
	}
	fmt.Printf("All repos pulled in: %v\n", dtEnd.Sub(dtStart))
}
