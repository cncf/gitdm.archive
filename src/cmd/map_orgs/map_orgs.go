package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"runtime/debug"
	"time"

	"gopkg.in/yaml.v2"
)

// gitHubUsers - list of GitHub user data from cncf/devstats.
type gitHubUsers []gitHubUser

// gitHubUser - single GitHug user entry from cncf/devstats `github_users.json` JSON.
type gitHubUser struct {
	Login       string   `json:"login"`
	Email       string   `json:"email"`
	Affiliation string   `json:"affiliation"`
	Name        string   `json:"name"`
	CountryID   *string  `json:"country_id"`
	Sex         *string  `json:"sex"`
	Tz          *string  `json:"tz"`
	SexProb     *float64 `json:"sex_prob"`
}

// allMappings contain all organization name mappings
type allMappings struct {
	Mappings [][2]string `yaml:"mappings"`
}

func fatalOnError(err error) {
	if err != nil {
		tm := time.Now()
		fmt.Printf("Error(time=%+v):\nError: '%s'\nStacktrace:\n%s\n", tm, err.Error(), string(debug.Stack()))
		fmt.Fprintf(os.Stderr, "Error(time=%+v):\nError: '%s'\nStacktrace:\n", tm, err.Error())
		panic("stacktrace")
	}
}

func fatalf(f string, a ...interface{}) {
	fatalOnError(fmt.Errorf(f, a...))
}

// getAffiliationsJSONBody - get affiliations JSON contents
// First try to get JSON from SH_LOCAL_JSON_PATH which defaults to "github_users.json"
// Fallback to SH_REMOTE_JSON_PATH which defaults to "https://github.com/cncf/devstats/raw/master/github_users.json"
func getAffiliationsJSONBody() []byte {
	jsonLocalPath := os.Getenv("SH_LOCAL_JSON_PATH")
	if jsonLocalPath == "" {
		jsonLocalPath = "github_users.json"
	}
	data, err := ioutil.ReadFile(jsonLocalPath)
	if err != nil {
		switch err := err.(type) {
		case *os.PathError:
			jsonRemotePath := os.Getenv("SH_REMOTE_JSON_PATH")
			if jsonRemotePath == "" {
				jsonRemotePath = "https://github.com/cncf/devstats/raw/master/github_users.json"
			}
			response, err2 := http.Get(jsonRemotePath)
			fatalOnError(err2)
			defer func() { _ = response.Body.Close() }()
			data, err2 = ioutil.ReadAll(response.Body)
			fatalOnError(err2)
			fmt.Printf("Read %d bytes remote JSON data from %s\n", len(data), jsonRemotePath)
			return data
		default:
			fatalOnError(err)
		}
	}
	fmt.Printf("Read %d bytes local JSON data from %s\n", len(data), jsonLocalPath)
	return data
}

// getMapOrgNamesYAMLBody - get map organization names YAML body
func getMapOrgNamesYAMLBody() []byte {
	yamlRemotePath := "https://github.com/LF-Engineering/dev-analytics-affiliation/raw/master/map_org_names.yaml"
	response, err := http.Get(yamlRemotePath)
	fatalOnError(err)
	defer func() { _ = response.Body.Close() }()
	data, err := ioutil.ReadAll(response.Body)
	fatalOnError(err)
	fmt.Printf("Read %d bytes remote YAML data from %s\n", len(data), yamlRemotePath)
	return data
}

func mapOrgs() {
	// Parse github_users.json
	var users gitHubUsers
	// Read json data from local file falling back to remote file
	data := getAffiliationsJSONBody()
	fatalOnError(json.Unmarshal(data, &users))

	// Parse DA's map_org_names.yaml
	var mapOrgNames allMappings
	// Read yaml data from local file falling back to remote file
	data = getMapOrgNamesYAMLBody()
	fatalOnError(yaml.Unmarshal(data, &mapOrgNames))
}

func main() {
	mapOrgs()
}
