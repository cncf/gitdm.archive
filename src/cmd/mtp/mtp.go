package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"runtime"
	"time"
)

func mtp(fn string) error {
	// grep -EHin '^commit [0-9a-f]{40}$' git.log | wc -l
	fmt.Printf("Reading %s...\n", fn)
	data, err := ioutil.ReadFile(fn)
	if err != nil {
		return err
	}
	fmt.Printf("Read %s: %d bytes\n", fn, len(data))
	fmt.Printf("Splitting %s...\n", fn)
	//files := bytes.Split(data, []byte("\x0a\x63\x6f\x6d\x6d\x69\x74\x20"))
	lines := bytes.Split(data, []byte("\x0a"))
	fmt.Printf("Split %s: %d lines\n", fn, len(lines))
	from := 0
	to := 0
	lLine := 0
	commits := [][]byte{}
	fmt.Printf("Merging %s...\n", fn)
	for i, line := range lines {
		lLine = len(line)
		if lLine >= 47 && line[0] == '\x63' && line[1] == '\x6f' && line[2] == '\x6d' && line[3] == '\x6d' && line[4] == '\x69' && line[5] == '\x74' && line[6] == '\x20' {
			if lLine != 47 {
				fmt.Printf("Non-standard commit-like line: %d: %+v: %d -> %d (%d bytes)\n", i, string(line), from, to, lLine)
			}
			to = i
			if to == from {
				continue
			}
			commit := bytes.Join(lines[from:to], []byte("\x0a"))
			from = i
			commits = append(commits, commit)
		} else {
			to++
		}
	}
	fmt.Printf("Merged %s: %d commits\n", fn, len(commits))
	//for i, commit := range commits {
	//  fmt.Printf("%d>>>: '%s'<<<\n", i, string(commit))
	//}
	ch := make(chan error)
	thrN := runtime.NumCPU()
	runtime.GOMAXPROCS(thrN)
	tCommits := [][][]byte{}
	for i := 0; i < thrN; i++ {
		tCommits = append(tCommits, [][]byte{})
	}
	for i, commit := range commits {
		t := i % thrN
		tCommits[t] = append(tCommits[t], commit)
	}
	fmt.Printf("%s: created %d tasks\n", fn, len(tCommits))
	for idx := range tCommits {
		go func(c chan error, i int, t [][]byte) {
	    // ~/dev/alt/gitdm/src/cncfdm.py -i git.log -r "^vendor/|/vendor/|^Godeps/" -R -n -b ./ -t -z -d -D -A -U -u -o all.txt -x all.csv -a all_affs.csv > all.out
	    // ~/dev/alt/gitdm/src/cncfdm.py -i git.log -r "^vendor/|/vendor/|^Godeps/" -R -n -b ./ -u -a all_affs.csv
			data = bytes.Join(t, []byte("\x0a"))
			fmt.Printf("Thread %d: I have %d bytes\n", i, len(data))
			c <- nil
		}(ch, idx, tCommits[idx])
	}
	go func(t int) {
		for {
			fmt.Printf("Heartbeat: %d threads\n", t)
			time.Sleep(1 * time.Second)
		}
	}(thrN)
	fmt.Printf("Waiting for %d tasks to finish\n", thrN)
	for i := 0; i < thrN; i++ {
		err := <-ch
		if err != nil {
			fmt.Printf("%d threads already finished, last thread returned error status: %+v\n", i+1, err)
		} else {
			fmt.Printf("%d threads already finished\n", i+1)
		}
	}
	return nil
}

func main() {
	dtStart := time.Now()
	fn := "git.log"
	if len(os.Args) >= 2 {
		fn = os.Args[1]
	}
	err := mtp(fn)
	dtEnd := time.Now()
	if err != nil {
		fmt.Printf("%+v\n", err)
	}
	fmt.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
