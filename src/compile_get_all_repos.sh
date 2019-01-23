#!/bin/sh
gofmt -s -w get_all_repos.go || exit 1
golint -set_exit_status get_all_repos.go || exit 2
go vet get_all_repos.go || exit 3
goconst get_all_repos.go || exit 4
goimports -w get_all_repos.go || exit 5
CGO_ENABLED=0 go build get_all_repos.go || exit 6
echo 'Compiled OK'

