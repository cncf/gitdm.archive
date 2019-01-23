package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"sort"
	"strings"
	"time"
)

// gitHubUsers - list of GitHub user data from cncf/gitdm.
type gitHubUsers []gitHubUser

// gitHubUser - single GitHug user entry from cncf/gitdm `github_users.json` JSON.
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

func levenshteinDist(s, t string) int {
	d := make([][]int, len(s)+1)
	for i := range d {
		d[i] = make([]int, len(t)+1)
	}
	for i := range d {
		d[i][0] = i
	}
	for j := range d[0] {
		d[0][j] = j
	}
	for j := 1; j <= len(t); j++ {
		for i := 1; i <= len(s); i++ {
			if s[i-1] == t[j-1] {
				d[i][j] = d[i-1][j-1]
			} else {
				min := d[i-1][j]
				if d[i][j-1] < min {
					min = d[i][j-1]
				}
				if d[i-1][j-1] < min {
					min = d[i-1][j-1]
				}
				d[i][j] = min + 1
			}
		}
	}
	return d[len(s)][len(t)]
}

func fatalOnError(err error) {
	if err != nil {
		tm := time.Now()
		fmt.Fprintf(os.Stderr, "Error(time=%+v):\nError: '%s'\nStacktrace:\n", tm, err.Error())
		panic("stacktrace")
	}
}

// Fatalf - it will call FatalOnError using fmt.Errorf with args provided
func fatalf(f string, a ...interface{}) {
	fatalOnError(fmt.Errorf(f, a...))
}

func checkSpell() {
	fn := "github_users.json"
	var users gitHubUsers
	data, err := ioutil.ReadFile(fn)
	if err != nil {
		fatalOnError(err)
		return
	}
	namesMap := make(map[string]int)
	fatalOnError(json.Unmarshal(data, &users))
	for _, user := range users {
		affs := user.Affiliation
		if affs == "?" || affs == "" {
			continue
		}
		affsAry := strings.Split(affs, ", ")
		for _, aff := range affsAry {
			ary := strings.Split(aff, " < ")
			company := strings.TrimSpace(ary[0])
			if company == "" {
				fatalf("wrong affs: %s", affs)
				continue
			}
			v, ok := namesMap[company]
			if !ok {
				namesMap[company] = 1
			} else {
				namesMap[company] = v + 1
			}
		}
	}
	invNamesMap := make(map[int][]string)
	namesAry := []string{}
	nAry := []int{}
	for name, n := range namesMap {
		namesAry = append(namesAry, name)
		nAry = append(nAry, n)
		v, ok := invNamesMap[n]
		if !ok {
			invNamesMap[n] = []string{name}
		} else {
			v = append(v, name)
			invNamesMap[n] = v
		}
	}
	sort.Sort(sort.Reverse(sort.IntSlice(nAry)))
	prevN := 0
	res := make(map[int][]string)
	for _, n1 := range nAry {
		if prevN == n1 {
			continue
		}
		if n1 < 6 {
			break
		}
		names1 := invNamesMap[n1]
		for _, name1 := range names1 {
			l1 := len(name1)
			for _, name2 := range namesAry {
				if name1 == name2 {
					continue
				}
				l2 := len(name2)
				dist := levenshteinDist(name1, name2)
				if dist > 0 && n1 >= 6 && l1 > 2*dist && l2 > 2*dist {
					la := (l1 + l2) / 4
					n2 := namesMap[name2]
					if dist < la && n2 <= 5 {
						txt := fmt.Sprintf("%s (%d occurences) is within %d distance from %s (%d occurences)\n", name1, n1, dist, name2, n2)
						v, ok := res[dist]
						if !ok {
							res[dist] = []string{txt}
						} else {
							v = append(v, txt)
							res[dist] = v
						}
					}
				}
			}
		}
		prevN = n1
	}
	dists := []int{4, 3, 2, 1}
	for _, dist := range dists {
		rows := res[dist]
		fmt.Printf("=========== start distance %d ===========\n", dist)
		for _, row := range rows {
			fmt.Printf("%s", row)
		}
		fmt.Printf("=========== end distance %d ===========\n", dist)
	}
}

func main() {
	checkSpell()
}
