package main

import (
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"runtime"
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
			f.Close()
			break
		} else if err != nil {
			f.Close()
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
	for _, file := range files {
		go func(c chan string, fn string) {
			c <- ""
		}(ch, file)
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
