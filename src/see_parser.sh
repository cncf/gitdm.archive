#!/bin/sh
git log -p -M | ./logparser.py | less

