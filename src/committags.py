#!/usr/bin/python
#
# Generate a database of commits and major versions they went into.
#
# committags [git-args]
#
# This code is part of the LWN git data miner.
#
# Copyright 2007-11 Eklektix, Inc.
# Copyright 2007-11 Jonathan Corbet <corbet@lwn.net>
#
# This file may be distributed under the terms of the GNU General
# Public License, version 2.
#
import sys
import re
import os
import pickle

git = 'git log --decorate '
if len(sys.argv) > 1:
    git += ' '.join(sys.argv[1:])
input = os.popen(git, 'r')

DB = { }
Tag = 'None'
Tags = 0

# LG: lets use given repo's commit tag format, here kubernetes
tagline = re.compile(r'^commit ([\da-f]+) \(tag: (v[0-9]\.[0-9]+.*)\)')
commit = re.compile(r'^commit ([\da-f]+)')

for line in input.readlines():
    if not line.startswith('commit'):
        continue  # This makes it go faster
    m = tagline.search(line)
    if m:
        DB[m.group(1)] = Tag = m.group(2)
        Tags += 1
    else:
        m = commit.search(line)
        if m:
            DB[m.group(1)] = Tag

print 'Found %d commits, %d tags' % (len(DB.keys()), Tags)
out = open('committags.db', 'w')
pickle.dump(DB, out)
out.close()
