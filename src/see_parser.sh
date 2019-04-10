#!/bin/sh
git log --all -p -M | ./logparser.py | less

