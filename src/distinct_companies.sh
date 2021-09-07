#!/bin/bash
cat github_users.json | grep '"affiliation"' | grep -v ', ' | sort | uniq | less
