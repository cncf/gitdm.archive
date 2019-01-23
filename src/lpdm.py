#!/usr/bin/pypy
#-*- coding:utf-8 -*-
#

#
# This code is part of the LWN git data miner.
#
# Copyright 2007-11 Eklektix, Inc.
# Copyright 2007-11 Jonathan Corbet <corbet@lwn.net>
# Copyright 2011 Germán Póo-Caamaño <gpoo@gnome.org>
#
# This file may be distributed under the terms of the GNU General
# Public License, version 2.


import database, ConfigFile, reports
import getopt, datetime
import sys

Today = datetime.date.today()

#
# Control options.
#
MapUnknown = 0
DevReports = 1
DumpDB = 0
CFName = 'gitdm.config'
DirName = ''

#
# Options:
#
# -b dir	Specify the base directory to fetch the configuration files
# -c cfile	Specify a configuration file
# -d		Output individual developer stats
# -h hfile	HTML output to hfile
# -l count	Maximum length for output lists
# -o file	File for text output
# -p prefix Prefix for CSV output
# -s		Ignore author SOB lines
# -u		Map unknown employers to '(Unknown)'
# -z		Dump out the hacker database at completion

def ParseOpts ():
    global MapUnknown, DevReports
    global DumpDB
    global CFName, DirName, Aggregate

    opts, rest = getopt.getopt (sys.argv[1:], 'b:dc:h:l:o:uz')
    for opt in opts:
        if opt[0] == '-b':
            DirName = opt[1]
        elif opt[0] == '-c':
            CFName = opt[1]
        elif opt[0] == '-d':
            DevReports = 0
        elif opt[0] == '-h':
            reports.SetHTMLOutput (open (opt[1], 'w'))
        elif opt[0] == '-l':
            reports.SetMaxList (int (opt[1]))
        elif opt[0] == '-o':
            reports.SetOutput (open (opt[1], 'w'))
        elif opt[0] == '-u':
            MapUnknown = 1
        elif opt[0] == '-z':
            DumpDB = 1

def LookupStoreHacker (name, email):
    email = database.RemapEmail (email)
    h = database.LookupEmail (email)
    if h: # already there
        return h
    elist = database.LookupEmployer (email, MapUnknown)
    h = database.LookupName (name)
    if h: # new email
        h.addemail (email, elist)
        return h
    return database.StoreHacker(name, elist, email)

class Bug:
    def __init__(self, id, owner, date, emails):
        self.id = id
        self.owner = LookupStoreHacker('Unknown hacker', 'unknown@hacker.net')
        self.date = date
        for email in emails:
            self.owner = LookupStoreHacker(owner, email)

    @classmethod
    def parse(cls, line):
        split = line.split()
        return cls(split[0], split[1], split[2], split[3:])

#
# Here starts the real program.
#
ParseOpts ()

#
# Read the config files.
#
ConfigFile.ConfigFile (CFName, DirName)

bugs = [Bug.parse(l) for l in sys.stdin]

for bug in bugs:
    bug.owner.addbugfixed(bug)
    empl = bug.owner.emailemployer(bug.owner.email[0], ConfigFile.ParseDate(bug.date))
    empl.AddBug(bug)

if DumpDB:
    database.DumpDB ()
database.MixVirtuals ()

#
# Say something
#
hlist = database.AllHackers ()
elist = database.AllEmployers ()
ndev = nempl = 0
for h in hlist:
    if len (h.bugsfixed) > 0:
        ndev += 1
for e in elist:
    if len(e.bugsfixed) > 0:
        nempl += 1
reports.Write ('Processed %d bugs from %d developers\n' % (len(bugs), ndev))
reports.Write ('%d employers found\n' % (nempl))

if DevReports:
    reports.DevBugReports (hlist, len(bugs))
reports.EmplBugReports (elist, len(bugs))
