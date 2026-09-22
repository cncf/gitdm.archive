GO_BIN_FILES=cmd/check_spell/check_spell.go cmd/mtp/mtp.go cmd/check_shas/check_shas.go cmd/map_orgs/map_orgs.go cmd/get_aff_files/get_aff_files.go
# GO_ENV=CGO_ENABLED=0
GO_ENV=CGO_ENABLED=1
GO_BUILD=go build -ldflags '-s -w'
# GO_BUILD=go build -ldflags '-s -w' -race
GO_FMT=gofmt -s -w
GO_LINT=golint -set_exit_status
GO_VET=go vet
GO_IMPORTS=goimports -w
GO_USEDEXPORTS=usedexports
GO_ERRCHECK=errcheck -asserts -ignore '[FS]?[Pp]rint*'
BINARIES=check_spell mtp check_shas map_orgs get_aff_files
STRIP=strip

all: check ${BINARIES}

check_spell: cmd/check_spell/check_spell.go
	 ${GO_ENV} ${GO_BUILD} -o check_spell cmd/check_spell/check_spell.go

mtp: cmd/mtp/mtp.go
	 ${GO_ENV} ${GO_BUILD} -o mtp cmd/mtp/mtp.go

check_shas: cmd/check_shas/check_shas.go
	 ${GO_ENV} ${GO_BUILD} -o check_shas cmd/check_shas/check_shas.go

map_orgs: cmd/map_orgs/map_orgs.go
	 ${GO_ENV} ${GO_BUILD} -o map_orgs cmd/map_orgs/map_orgs.go

get_aff_files: cmd/get_aff_files/get_aff_files.go
	 ${GO_ENV} ${GO_BUILD} -o get_aff_files cmd/get_aff_files/get_aff_files.go

fmt: ${GO_BIN_FILES}
	./for_each_go_file.sh "${GO_FMT}"

lint: ${GO_BIN_FILES}
	./for_each_go_file.sh "${GO_LINT}"

vet: ${GO_BIN_FILES}
	./for_each_go_file.sh "${GO_VET}"

imports: ${GO_BIN_FILES}
	./for_each_go_file.sh "${GO_IMPORTS}"

usedexports: ${GO_BIN_FILES}
	${GO_USEDEXPORTS} ./...

errcheck: ${GO_BIN_FILES}
	${GO_ERRCHECK} cmd/check_spell/check_spell.go
	${GO_ERRCHECK} cmd/check_shas/check_shas.go
	${GO_ERRCHECK} cmd/map_orgs/map_orgs.go
	${GO_ERRCHECK} cmd/get_aff_files/get_aff_files.go

check: fmt lint imports vet usedexports errcheck

strip: ${BINARIES}
	${STRIP} ${BINARIES}

clean:
	rm -f ${BINARIES}
