package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"sort"
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

func genAffFiles(jsonFile string) (err error) {
	var (
		data  []byte
		users gitHubUsers
	)
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
	cdata := map[string]map[string]map[string][][3]string{}
	ldata := map[string]map[string]string{}
	for login, rows := range logins {
		affs := map[string][]string{}
		for _, row := range rows {
			a := *row.Affiliation
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
	return
	/*
		  ldata = {}
		  cdata = {}
		  logins.each do |login, rows|
		    affs = {}
		    rows.each do |row|
		      a = row['affiliation']
		      e = row['email']
		      affs[a] = [] unless affs.key?(a)
		      affs[a] << e
		    end
		    affs2 = {}
		    affs.each do |daff, emails|
		      aff = sort_and_add_dates(daff)
		      semails = emails.join(', ')
		      affs2[aff] = semails
		    end
		    affs2.each do |aff, emails|
		      arr = aff.split ','
		      arr.each do |d|
		        d = d.strip
		        arr2 = d.split '<'
		        l = arr2.length
		        binding.pry if l != 3
		        pdt = arr2[0].strip
		        c = arr2[1].strip
		        dt = arr2[2].strip
		        cdata[c] = {} unless cdata.key?(c)
		        cdata[c][login] = {} unless cdata[c].key?(login)
		        cdata[c][login][emails] = [] unless cdata[c][login].key?(emails)
		        cdata[c][login][emails] << [pdt, c, dt]
		      end
		    end
		    ldata[login] = affs2
		  end

		  puts "generating developer affiliations file..."
		  t = ''
		  ldata.keys.sort.each do |login|
		    data = ldata[login]
		    m = {}
		    data.each do |k, v|
		      v2 = v.split(', ').sort.join(', ')
		      m[v2] = k
		    end
		    m.keys.sort.each do |emails|
		      affs = m[emails]
		      t += login + ': ' + emails + "\n"
		      affs.split(', ').each do |aff|
		        ary = aff.split(' < ')
		        binding.pry if ary.length != 3
		        t += "\t" + ary[1]
		        from = ary[0]
		        t += ' from ' + from if from != '1900-01-01'
		        to = ary[2]
		        t += ' until ' + to if to != '2100-01-01'
		        t += "\n"
		      end
		    end
		  end
		  hdr = "# This is the main developers affiliations file.\n"
		  hdr += "# If you see your name with asterisk '*' sign - it means that\n"
		  hdr += "# multiple affiliations were found for you with different email addresses.\n"
		  hdr += "# Please merge all of them into one then.\n"
		  hdr += "# Note that email addresses below are \"best effort\" and are out-of-date\n"
		  hdr += "# or inaccurate in many cases. Please do not rely on this email information\n"
		  hdr += "# without verification.\n"
		  binding.pry
		  File.write '../developers_affiliations.txt', hdr + t

		  t = ''
		  cdata.keys.sort.each do |company|
		    t += company + ":\n"
		    data = cdata[company]
		    data.keys.sort.each do |login|
		      emd = data[login]
		      m = {}
		      emd.each do |k, v|
		        k2 = k.split(', ').sort.join(', ')
		        m[k2] = v
		      end
		      m.keys.sort.each do |emails|
		        affs = m[emails]
		        t += "\t" + login + ': ' + emails
		        l = affs.length
		        affs.each_with_index do |aff, i|
		          s = ''
		          from = aff[0]
		          to = aff[2]
		          binding.pry if aff[1] != company
		          s += ' from ' + from if from != '1900-01-01'
		          s += ' until ' + to if to != '2100-01-01'
		          if s != ''
		            t += s
		            t += ',' if i < l - 1
		          end
		        end
		        t += "\n"
		      end
		    end
		  end
		  hdr =  "# This file is derived from developers_affiliations.txt and so should not be edited directly.\n"
		  hdr += "# If you see an error, please update developers_affiliations.txt and this file will be fixed\n"
		  hdr += "# when regenerated.\n"
		  File.write '../company_developers.txt', hdr + t
		end
	*/
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
