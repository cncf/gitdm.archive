#!/bin/sh
git rm --cached `git ls-files -i --exclude-from=.gitignore`
