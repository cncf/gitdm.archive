Please use `*.sh` scripts to run analytics (all*.sh for full analysis and
rels*.sh for per release stats)
This program assumes that gitdm lives in: `~/dev/cncf/gitdm/`
And kubernetes in `~/dev/go/src/k8s.io/kubernetes/`
output files are placed in `kubernetes/` directory.

This is an iterational process:
Run any of scripts. Review its output in kubernetes directory.
iteratively adjust mappings to handle more authors (config/mappings is in
`cncf-config/`)

