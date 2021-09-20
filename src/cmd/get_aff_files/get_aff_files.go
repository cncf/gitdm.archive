package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"
	"runtime"
	"sort"
	"strconv"
	"strings"

	json "github.com/json-iterator/go"
)

// gitHubUsers - list of GitHub user data from cncf/devstats.
type gitHubUsers []gitHubUser

// MODE - use named fields (name type gitHubUserStr -> gitHubUser)
// gitHubUser - single GitHug user entry from cncf/devstats `github_users.json` JSON.
type gitHubUser struct {
	Login       string  `json:"login"`
	Email       string  `json:"email"`
	Affiliation *string `json:"affiliation"`
}

func sortAndAddDates(a string) string {
	affs := strings.Split(a, ",")
	l := len(affs)
	sa := []string{}
	for _, aff := range affs {
		aff = strings.TrimSpace(aff)
		ary := strings.Split(aff, "<")
		var dt string
		if len(ary) == 1 {
			dt = "2100-01-01"
		} else {
			dt = strings.TrimSpace(ary[1])
		}
		c := strings.TrimSpace(ary[0])
		sa = append(sa, dt+" < "+c)
	}
	sort.Strings(sa)
	s := ""
	for i, aff := range sa {
		ary := strings.Split(aff, "<")
		var dt string
		if i == 0 {
			dt = "1900-01-01"
		} else {
			prev := sa[i-1]
			ary2 := strings.Split(prev, "<")
			dt = strings.TrimSpace(ary2[0])
		}
		s += dt + " < " + strings.TrimSpace(ary[1]) + " < " + strings.TrimSpace(ary[0])
		if i < l-1 {
			s += ", "
		}
	}
	// fmt.Printf("'%s' -> '%s'\n", a, s)
	return s
}

func correctWhitespace(a string) string {
	ary := strings.Split(a, ",")
	items := []string{}
	for _, item := range ary {
		item := strings.TrimSpace(item)
		ary2 := strings.Split(item, "<")
		if len(ary2) == 1 {
			items = append(items, item)
			continue
		}
		items = append(items, strings.TrimSpace(ary2[0])+" < "+strings.TrimSpace(ary2[1]))
	}
	return strings.Join(items, ", ")
}

func genAffFiles(jsonFile string) (err error) {
	var (
		data  []byte
		users gitHubUsers
	)
	fmt.Printf("reading %s\n", jsonFile)
	data, err = ioutil.ReadFile(jsonFile)
	if err != nil {
		return
	}
	err = json.Unmarshal(data, &users)
	if err != nil {
		return
	}
	fmt.Printf("read %d users\n", len(users))
	logins := map[string][]gitHubUser{}
	for _, row := range users {
		if row.Affiliation == nil {
			continue
		}
		a := *row.Affiliation
		if a == "" || a == "?" || a == "NotFound" || a == "(Unknown)" {
			continue
		}
		l := row.Login
		data, ok := logins[l]
		if !ok {
			logins[l] = []gitHubUser{row}
			continue
		}
		data = append(data, row)
		logins[l] = data
	}
	fmt.Printf("generated logins data\n")
	cdata := map[string]map[string]map[string][][3]string{}
	ldata := map[string]map[string]string{}
	for login, rows := range logins {
		affs := map[string][]string{}
		for _, row := range rows {
			a := correctWhitespace(*row.Affiliation)
			e := row.Email
			data, ok := affs[a]
			if !ok {
				affs[a] = []string{e}
				continue
			}
			data = append(data, e)
			affs[a] = data
		}
		affs2 := map[string]string{}
		for daff, emails := range affs {
			aff := sortAndAddDates(daff)
			affs2[aff] = strings.Join(emails, ", ")
		}
		for aff, emails := range affs2 {
			arr := strings.Split(aff, ",")
			for _, d := range arr {
				d := strings.TrimSpace(d)
				arr2 := strings.Split(d, "<")
				pdt := strings.TrimSpace(arr2[0])
				c := strings.TrimSpace(arr2[1])
				dt := strings.TrimSpace(arr2[2])
				_, ok := cdata[c]
				if !ok {
					cdata[c] = make(map[string]map[string][][3]string)
				}
				_, ok = cdata[c][login]
				if !ok {
					cdata[c][login] = make(map[string][][3]string)
				}
				data, ok := cdata[c][login][emails]
				if !ok {
					cdata[c][login][emails] = [][3]string{{pdt, c, dt}}
					continue
				}
				data = append(data, [3]string{pdt, c, dt})
				cdata[c][login][emails] = data
			}
		}
		ldata[login] = affs2
	}
	// fmt.Printf("%+v\n%+v\n", ldata["lukaszgryglicki"], cdata["CNCF"]["lukaszgryglicki"])
	// fmt.Printf("ldata: %+v\ncdata: %+v\n", ldata, cdata)
	fmt.Printf("generated affiliations mappings\n")
	lk := []string{}
	for l := range ldata {
		lk = append(lk, l)
	}
	sort.Strings(lk)
	t := map[int]string{}
	thrN := runtime.NumCPU()
	fmt.Printf("using %d threads\n", thrN)
	runtime.GOMAXPROCS(thrN)
	ch := make(chan [2]string)
	nThreads := 0
	for i := range lk {
		go func(ch chan [2]string, idx int) {
			ret := [2]string{strconv.Itoa(idx), ""}
			t := ""
			defer func() {
				ret[1] = t
				ch <- ret
			}()
			login := lk[idx]
			data := ldata[login]
			m := map[string]string{}
			for k, v := range data {
				ary := strings.Split(v, ", ")
				sort.Strings(ary)
				v2 := strings.Join(ary, ", ")
				m[v2] = k
			}
			mk := []string{}
			for k := range m {
				mk = append(mk, k)
			}
			sort.Strings(mk)
			for _, emails := range mk {
				affs := m[emails]
				t += login + ": " + emails + "\n"
				affsAry := strings.Split(affs, ", ")
				for _, aff := range affsAry {
					ary := strings.Split(aff, " < ")
					t += "\t" + ary[1]
					from := ary[0]
					if from != "1900-01-01" {
						t += " from " + from
					}
					to := ary[2]
					if to != "2100-01-01" {
						t += " until " + to
					}
					t += "\n"
				}
			}
		}(ch, i)
		nThreads++
		if nThreads == thrN {
			data := <-ch
			nThreads--
			idx, _ := strconv.Atoi(data[0])
			t[idx] = data[1]
		}
	}
	for nThreads > 0 {
		data := <-ch
		nThreads--
		idx, _ := strconv.Atoi(data[0])
		t[idx] = data[1]
	}
	hdr := "# This is the main developers affiliations file.\n"
	hdr += "# If you see your name with asterisk '*' sign - it means that\n"
	hdr += "# multiple affiliations were found for you with different email addresses.\n"
	hdr += "# Please merge all of them into one then.\n"
	hdr += "# Note that email addresses below are \"best effort\" and are out-of-date\n"
	hdr += "# or inaccurate in many cases. Please do not rely on this email information\n"
	hdr += "# without verification.\n"
	var file *os.File
	file, err = os.OpenFile("../developers_affiliations.txt", os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0644)
	if err != nil {
		return
	}
	writer := bufio.NewWriter(file)
	_, _ = writer.WriteString(hdr)
	for i := range lk {
		_, _ = writer.WriteString(t[i])
	}
	_ = writer.Flush()
	_ = file.Close()
	fmt.Printf("saved developer affiliations file\n")
	ck := []string{}
	for c := range cdata {
		ck = append(ck, c)
	}
	sort.Strings(ck)
	t = map[int]string{}
	ch = make(chan [2]string)
	nThreads = 0
	for i := range ck {
		go func(ch chan [2]string, idx int) {
			ret := [2]string{strconv.Itoa(idx), ""}
			t := ""
			defer func() {
				ret[1] = t
				// fmt.Printf("%+v\n", ret)
				ch <- ret
			}()
			company := ck[idx]
			t += company + ":\n"
			data := cdata[company]
			// fmt.Printf("%s: %+v\n", company, data)
			dk := []string{}
			for d := range data {
				dk = append(dk, d)
			}
			sort.Strings(dk)
			for _, login := range dk {
				emd := data[login]
				// fmt.Printf("%s: %s: %+v\n", company, login, emd)
				m := map[string][][3]string{}
				for k, v := range emd {
					ary := strings.Split(k, ", ")
					sort.Strings(ary)
					k2 := strings.Join(ary, ", ")
					m[k2] = v
				}
				mk := []string{}
				for k := range m {
					mk = append(mk, k)
				}
				sort.Strings(mk)
				for _, emails := range mk {
					affs := m[emails]
					// fmt.Printf("%s: %s: %s: %+v\n", company, login, emails, affs)
					t += "\t" + login + ": " + emails
					l := len(affs)
					for i, aff := range affs {
						s := ""
						from := aff[0]
						to := aff[2]
						if from != "1900-01-01" {
							s += " from " + from
						}
						if to != "2100-01-01" {
							s += " until " + to
						}
						if s != "" {
							t += s
							if i < l-1 {
								t += ","
							}
						}
					}
					t += "\n"
				}
			}
		}(ch, i)
		nThreads++
		if nThreads == thrN {
			data := <-ch
			nThreads--
			idx, _ := strconv.Atoi(data[0])
			t[idx] = data[1]
		}
	}
	for nThreads > 0 {
		data := <-ch
		nThreads--
		idx, _ := strconv.Atoi(data[0])
		t[idx] = data[1]
	}
	hdr = "# This file is derived from developers_affiliations.txt and so should not be edited directly.\n"
	hdr += "# If you see an error, please update developers_affiliations.txt and this file will be fixed\n"
	hdr += "# when regenerated.\n"
	file, err = os.OpenFile("../company_developers.txt", os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0644)
	if err != nil {
		return
	}
	writer = bufio.NewWriter(file)
	_, _ = writer.WriteString(hdr)
	for i := range ck {
		_, _ = writer.WriteString(t[i])
	}
	_ = writer.Flush()
	_ = file.Close()
	fmt.Printf("saved company developers file\n")
	return
}

func main() {
	if len(os.Args) < 2 {
		fmt.Printf("Missing argument: json_file (github_users.json)\n")
		os.Exit(1)
	}
	err := genAffFiles(os.Args[1])
	if err != nil {
		fmt.Fprintf(os.Stderr, "%s: %v\n", os.Args[1], err)
	}
}
