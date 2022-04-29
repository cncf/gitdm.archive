package main

import (
	"crypto/sha256"
	"encoding/csv"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"regexp"
	"runtime"
	"sort"
	"strings"
	"sync"
	"time"
)

func checkSHAs(files []string) error {
	fmt.Printf("Checking %d files\n", len(files))
	cfn := "./cncf-config/forbidden.csv"
	f, err := os.Open(cfn)
	if err != nil {
		return err
	}
	shas := make(map[string]struct{})
	reader := csv.NewReader(f)
	for {
		row, err := reader.Read()
		if err == io.EOF {
			_ = f.Close()
			break
		} else if err != nil {
			_ = f.Close()
			fmt.Printf("Reading %s\n", cfn)
			return err
		}
		if len(row) != 1 {
			return fmt.Errorf("unexpected row: %+v, it should contain only one column: sha", row)
		}
		if row[0] == "sha" {
			continue
		}
		if len(row[0]) != 64 {
			return fmt.Errorf("unexpected column: %+v, it should have length 64, has: %d", row[0], len(row[0]))
		}
		shas[row[0]] = struct{}{}
	}
	fmt.Printf("Read %d forbiden SHAs\n", len(shas))
	thrN := runtime.NumCPU()
	nThreads := 0
	runtime.GOMAXPROCS(thrN)
	ch := make(chan string)
	lMap := make(map[string][][2]int)
	var lMapMtx sync.Mutex
	nFiles := len(files)
	for idx, file := range files {
		if idx%100 == 99 {
			fmt.Printf("Files analysis %d/%d\n", idx+1, nFiles)
		}
		go func(c chan string, i int, fn string) {
			data, err := ioutil.ReadFile(fn)
			if err != nil {
				c <- fn + ": " + err.Error()
				return
			}
			lines1 := strings.Split(string(data), "\r")
			lines2 := strings.Split(string(data), "\n")
			lines := lines1
			if len(lines2) > len(lines1) {
				lines = lines2
			}
			for j, line := range lines {
				line = strings.TrimSpace(line)
				if line == "" {
					continue
				}
				lMapMtx.Lock()
				v, ok := lMap[line]
				if !ok {
					lMap[line] = [][2]int{{i, j}}
				} else {
					v = append(v, [2]int{i, j})
					lMap[line] = v
				}
				lMapMtx.Unlock()
			}
			c <- ""
		}(ch, idx, file)
		nThreads++
		if nThreads == thrN {
			res := <-ch
			nThreads--
			if res != "" {
				fmt.Printf("%s\n", res)
			}
		}
	}
	for nThreads > 0 {
		res := <-ch
		nThreads--
		if res != "" {
			fmt.Printf("%s\n", res)
		}
	}
	nThreads = 0
	//nonWordRE := regexp.MustCompile(`[^\w]`)
	nonWordRE := regexp.MustCompile(`[\s+,;'"/\\]`)
	chs := make(chan struct{})
	tMap := make(map[string][][3]int)
	shaCache := make(map[string]string)
	var (
		tMapMtx  sync.Mutex
		cacheMtx sync.Mutex
	)
	k := 0
	nLines := len(lMap)
	all := os.Getenv("ALL") != ""
	fmt.Printf("Checking %d lines\n", nLines)
	for line, data := range lMap {
		if k%100000 == 99999 {
			fmt.Printf("Lines analysis %d/%d\n", k+1, nLines)
		}
		k++
		go func(c chan struct{}, l string, data [][2]int) {
			tokens := nonWordRE.Split(l, -1)
			toks := []string{}
			for _, token := range tokens {
				token = strings.TrimSpace(token)
				if len(token) < 4 {
					continue
				}
				toks = append(toks, token)
			}
			for i, token := range toks {
				if !all {
					cacheMtx.Lock()
					sum, ok := shaCache[token]
					if !ok {
						sum = fmt.Sprintf("%x", sha256.Sum256([]byte(token)))
						shaCache[token] = sum
					}
					cacheMtx.Unlock()
					_, ok = shas[sum]
					if !ok {
						continue
					}
				}
				tMapMtx.Lock()
				v, ok := tMap[token]
				if !ok {
					v = [][3]int{}
					for _, d := range data {
						v = append(v, [3]int{d[0], d[1], i})
					}
					tMap[token] = v
				} else {
					for _, d := range data {
						v = append(v, [3]int{d[0], d[1], i})
					}
					tMap[token] = v
				}
				tMapMtx.Unlock()
			}
			c <- struct{}{}
		}(chs, line, data)
		nThreads++
		if nThreads == thrN {
			<-chs
			nThreads--
		}
	}
	for nThreads > 0 {
		<-chs
		nThreads--
	}
	keys := []string{}
	for k := range tMap {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	if len(keys) > 0 {
		fmt.Printf("Found %d tokens that need to be removed:\n===========================================\n", len(keys))
	}
	fixFiles := make(map[string]struct{})
	for _, k := range keys {
		data := tMap[k]
		fmt.Printf("%s: ", k)
		for _, row := range data {
			fmt.Printf("%s:%d:%d ", files[row[0]], row[1]+1, row[2]+1)
			fixFiles[files[row[0]]] = struct{}{}
		}
		fmt.Printf("\n\n")
	}
	if len(keys) > 0 {
		fix := []string{}
		for f := range fixFiles {
			fix = append(fix, `'`+f+`'`)
		}
		fmt.Printf("===========================================\n")
		fmt.Printf("Keys VIM search pattern: '%s'\n", strings.Join(keys, `\|`))
		fmt.Printf("VIM command: vim %s\n", strings.Join(fix, " "))
	} else {
		fmt.Printf("Nothing to remove, all data is OK\n")
	}
	return nil
}

func main() {
	dtStart := time.Now()
	err := checkSHAs(os.Args[1:])
	dtEnd := time.Now()
	if err != nil {
		fmt.Printf("%+v\n", err)
	}
	fmt.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
