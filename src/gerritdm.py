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

def LookupStoreHacker (date, name, email):
    email = database.RemapEmail (email)
    h = database.LookupEmail (email)
    if h: # already there
        return date, h
    elist = database.LookupEmployer (email, MapUnknown)
    h = database.LookupName (name)
    if h: # new email
        h.addemail (email, elist)
        return date, h
    return date, database.StoreHacker(name, elist, email)

#
# Here starts the real program.
#
ParseOpts ()

#
# Read the config files.
#
ConfigFile.ConfigFile (CFName, DirName)

reviews = [LookupStoreHacker(*l.split()[:3]) for l in sys.stdin]

for date, reviewer in reviews:
    reviewer.addreview(reviewer)
    empl = reviewer.emailemployer(reviewer.email[0], ConfigFile.ParseDate(date))
    empl.AddReview(reviewer)

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
    if len(h.reviews) > 0:
        ndev += 1
for e in elist:
    if len(e.reviews) > 0:
        nempl += 1
reports.Write ('Processed %d review from %d developers\n' % (len(reviews), ndev))
reports.Write ('%d employers found\n' % (nempl))

if DevReports:
    reports.DevReviews (hlist, len(reviews))
reports.EmplReviews (elist, len(reviews))
