package main

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"runtime"
	"sort"
	"strings"
	"time"

	"github.com/tushar2708/altcsv"
)

type allAffs struct {
	email   string
	name    string
	company string
	dateTo  string
	source  string
}

type allAffsAry []allAffs

func (aa allAffsAry) Len() int {
	return len(aa)
}

func (aa allAffsAry) Swap(i, j int) {
	aa[i], aa[j] = aa[j], aa[i]
}

func (aa allAffsAry) Less(i, j int) bool {
	if aa[i].email == aa[j].email {
		return aa[i].dateTo < aa[j].dateTo
	}
	return aa[i].email < aa[j].email
}

func execCommand(debug int, output bool, cmdAndArgs []string, env map[string]string) (string, error) {
	// Execution time
	dtStart := time.Now()
	// STDOUT pipe size
	pipeSize := 0x100

	// Command & arguments
	command := cmdAndArgs[0]
	arguments := cmdAndArgs[1:]
	if debug > 0 {
		var args []string
		for _, arg := range cmdAndArgs {
			argLen := len(arg)
			if argLen > 0x200 {
				arg = arg[0:0x100] + "..." + arg[argLen-0x100:argLen]
			}
			if strings.Contains(arg, " ") {
				args = append(args, "'"+arg+"'")
			} else {
				args = append(args, arg)
			}
		}
		fmt.Printf("%s\n", strings.Join(args, " "))
	}
	cmd := exec.Command(command, arguments...)

	// Environment setup (if any)
	if len(env) > 0 {
		newEnv := os.Environ()
		for key, value := range env {
			newEnv = append(newEnv, key+"="+value)
		}
		cmd.Env = newEnv
		if debug > 0 {
			fmt.Printf("Environment Override: %+v\n", env)
			if debug > 2 {
				fmt.Printf("Full Environment: %+v\n", newEnv)
			}
		}
	}

	// Capture STDOUT (non buffered - all at once when command finishes), only used on error and when no buffered/piped version used
	// Which means it is used on error when debug <= 1
	// In debug > 1 mode, we're displaying STDOUT during execution, and storing results to 'outputStr'
	// Capture STDERR (non buffered - all at once when command finishes)
	var (
		stdOut    bytes.Buffer
		stdErr    bytes.Buffer
		outputStr string
	)
	cmd.Stderr = &stdErr
	if debug <= 1 {
		cmd.Stdout = &stdOut
	}

	// Pipe command's STDOUT during execution (if debug > 1)
	// Or just starts command when no STDOUT debug
	if debug > 1 {
		stdOutPipe, e := cmd.StdoutPipe()
		if e != nil {
			return "", e
		}
		e = cmd.Start()
		if e != nil {
			return "", e
		}
		buffer := make([]byte, pipeSize, pipeSize)
		nBytes, e := stdOutPipe.Read(buffer)
		for e == nil && nBytes > 0 {
			fmt.Printf("%s", buffer[:nBytes])
			outputStr += string(buffer[:nBytes])
			nBytes, e = stdOutPipe.Read(buffer)
		}
		if e != io.EOF {
			return "", e
		}
	} else {
		e := cmd.Start()
		if e != nil {
			return "", e
		}
	}
	// Wait for command to finish
	err := cmd.Wait()

	// If error - then output STDOUT, STDERR and error info
	if err != nil {
		if debug <= 1 {
			outStr := stdOut.String()
			if len(outStr) > 0 {
				fmt.Printf("%v\n", outStr)
			}
		}
		errStr := stdErr.String()
		if len(errStr) > 0 {
			fmt.Printf("STDERR:\n%v\n", errStr)
		}
		if err != nil {
			return stdOut.String(), err
		}
	}

	// If debug > 1 display STDERR contents as well (if any)
	if debug > 1 {
		errStr := stdErr.String()
		if len(errStr) > 0 {
			fmt.Printf("Errors:\n%v\n", errStr)
		}
	}
	if debug > 0 {
		info := strings.Join(cmdAndArgs, " ")
		lenInfo := len(info)
		if lenInfo > 0x280 {
			info = info[0:0x140] + "..." + info[lenInfo-0x140:lenInfo]
		}
		dtEnd := time.Now()
		fmt.Printf("%s: %+v\n", info, dtEnd.Sub(dtStart))
	}
	outStr := ""
	if output {
		if debug <= 1 {
			outStr = stdOut.String()
		} else {
			outStr = outputStr
		}
	}
	return outStr, nil
}

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
			// ~/dev/alt/gitdm/src/cncfdm.py -i git.log -r "^vendor/|/vendor/|^Godeps/" -R -n -b ./ -d -u -a all_affs.csv
			data = bytes.Join(t, []byte("\x0a"))
			fmt.Printf("Thread %d: I have %d bytes from %d commits\n", i, len(data), len(t))
			tfn := fmt.Sprintf("%s_%d", fn, i)
			err := ioutil.WriteFile(tfn, data, 0644)
			if err != nil {
				c <- err
				return
			}
			cmd := []string{"./cncfdm.py", "-i", tfn, "-r", "^vendor/|/vendor/|^Godeps/", "-R", "-n", "-b", "./", "-d", "-u", "-a", tfn + ".csv"}
			res, err := execCommand(0, false, cmd, nil)
			if err != nil {
				fmt.Printf("Thread %d error: %+v, output:\n%s\n", i, err, res)
				c <- err
				return
			}
			c <- nil
		}(ch, idx, tCommits[idx])
	}
	go func(t int) {
		cmd := []string{"ls", "-s"}
		for i := 0; i < thrN; i++ {
			cmd = append(cmd, fmt.Sprintf("%s_%d.csv", fn, i))
		}
		time.Sleep(10 * time.Second)
		for {
			res, err := execCommand(0, true, cmd, nil)
			if err != nil {
				fmt.Printf("Heartbeat: %d threads, error: %+v\n", t, err)
			} else {
				fmt.Printf("Heartbeat: %d threads\n%s\n", t, res)
			}
			time.Sleep(30 * time.Second)
		}
	}(thrN)
	fmt.Printf("Waiting for %d tasks to finish\n", thrN)
	for i := 0; i < thrN; i++ {
		err := <-ch
		if err != nil {
			fmt.Printf("%d threads already finished, last thread returned error status: %+v\n", i+1, err)
			return err
		}
		fmt.Printf("%d threads already finished\n", i+1)
	}
	csvData := make(map[allAffs]struct{})
	aff := allAffs{}
	for i := 0; i < thrN; i++ {
		cfn := fmt.Sprintf("%s_%d.csv", fn, i)
		f, err := os.Open(cfn)
		if err != nil {
			return err
		}
		reader := csv.NewReader(f)
		reader.FieldsPerRecord = -1
		for {
			row, err := reader.Read()
			if err == io.EOF {
				f.Close()
				break
			} else if err != nil {
				f.Close()
				fmt.Printf("Reading %s\n", cfn)
				return err
			}
			if len(row) == 4 {
				row = append(row, "config")
			}
			aff.email = row[0]
			aff.name = row[1]
			aff.company = row[2]
			aff.dateTo = row[3]
			aff.source = row[4]
			csvData[aff] = struct{}{}
		}
	}
	var csvAry allAffsAry
	for key := range csvData {
		csvAry = append(csvAry, key)
	}
	sort.Sort(csvAry)
	var writer *altcsv.Writer
	ofn := fn + ".csv"
	oFile, err := os.Create(ofn)
	if err != nil {
		return err
	}
	defer func() { _ = oFile.Close() }()
	writer = altcsv.NewWriter(oFile)
	writer.AllQuotes = true
	defer writer.Flush()
	hdr := []string{"email", "name", "company", "date_to", "source"}
	err = writer.Write(hdr)
	if err != nil {
		fmt.Printf("Wrining header: %+v\n", hdr)
		return err
	}
	for i, row := range csvAry {
		vals := []string{row.email, row.name, row.company, row.dateTo, row.source}
		err = writer.Write(vals)
		if err != nil {
			fmt.Printf("Wrining %d row: %+v, vals: %+v\n", i, row, vals)
			return err
		}
	}
	fmt.Printf("Final %s written, you can now review it and eventually move to all_affs.csv, also take a look at enchance_msg.txt file to find usual thrash data\n", ofn)
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
