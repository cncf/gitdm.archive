#!/usr/bin/python
#-*- coding:utf-8 -*-
#

#
# This code is part of the LWN git data miner.
#
# Copyright 2007-12 Eklektix, Inc.
# Copyright 2007-12 Jonathan Corbet <corbet@lwn.net>
# Copyright 2011 Germán Póo-Caamaño <gpoo@gnome.org>
#
# This file may be distributed under the terms of the GNU General
# Public License, version 2.


import database, csvdump, ConfigFile, reports
import getopt, datetime
import os, re, sys, rfc822, string
import logparser
from patterns import patterns, email_encode
import pdb

Today = datetime.date.today()

#
# Remember author names we have griped about.
#
GripedAuthorNames = [ ]

#
# Control options.
#
MapUnknown = 0  # 0=no map, 1=map to email domain name, 2=map to (Unknown)
DevReports = 1
DateStats = 0
AuthorSOBs = 1
FileStats = None
FileFilter = None
InvertFilter = False
CSVFile = None
CSVPrefix = None
AffFile = None
DumpDB = 0
CFName = 'gitdm.config-cncf'
DirName = ''
Aggregate = 'month'
Numstat = 0
ReportByFileType = 0
ReportUnknowns = False
ReportAll = False
InputData = sys.stdin
InputDataIsFile = False
DebugHalt = False
DateFrom = datetime.datetime(1970, 1, 1)
DateTo = datetime.datetime(2069, 1, 1)
BotEmails = [
    "27856297+dependabot-preview[bot]@users.noreply.github.com",
    "31301654+imgbot[bot]@users.noreply.github.com",
    "35031835+jenkins-x-bot@users.noreply.github.com",
    "35295607+pikbot@users.noreply.github.com",
    "36644060+envoy-java-control-plane-bot@users.noreply.github.com",
    "37929162+mergify[bot]@users.noreply.github.com",
    "39114087+corbot[bot]@users.noreply.github.com",
    "41968677+kubermatic-bot@users.noreply.github.com",
    "43237426+jenkins-x-bot-test@users.noreply.github.com",
    "48335577+tekton-robot@users.noreply.github.com",
    "49699333+dependabot[bot]@users.noreply.github.com",
    "51717117+knative-prow-updater-robot@users.noreply.github.com",
    "AppVeyorBot@users.noreply.github.com",
    "CNCF-Bot@users.noreply.github.com",
    "JoeTalbot@users.noreply.github.com",
    "KernelPRBot@users.noreply.github.com",
    "PikBot@users.noreply.github.com",
    "abbott@squareup.com",
    "alainjobart-bot@users.noreply.github.com",
    "azure-pipelines[bot]@users.noreply.github.com",
    "badges@fossa.io",
    "bot@example.com",
    "build-bot@dangernoodle.io",
    "cadvisorJenkinsBot@users.noreply.github.com",
    "containers-bot@bitnami.com",
    "corbot[bot]@users.noreply.github.com",
    "coreosbot@users.noreply.github.com",
    "covbot@users.noreply.github.com",
    "data-plane-api@users.noreply.github.com",
    "dependabot-preview[bot]@users.noreply.github.com",
    "dependabot[bot]@users.noreply.github.com",
    "deploy-bot@opentracing.io",
    "deploy@travis-ci.org",
    "dev-rowbot@users.noreply.github.com",
    "devtools-jx-bot-proof@users.noreply.github.com",
    "envoy-bot@users.noreply.github.com",
    "envoy-docs@users.noreply.github.com",
    "envoy-filter-example@users.noreply.github.com",
    "envoy-java-control-plane-bot@users.noreply.github.com",
    "eparis-bot@users.noreply.github.com",
    "fejta-bot@users.noreply.github.com",
    "gerrit@onlab.us",
    "git-bot@tilosp.de",
    "github+dockerlibrarybot@infosiftr.com",
    "golangcibot@users.noreply.github.com",
    "googlebot@users.noreply.github.com",
    "greenkeeper[bot]@users.noreply.github.com",
    "hudson@openstack.org",
    "imgbot[bot]@users.noreply.github.com",
    "info@arangodb.com",
    "info@bitergia.com",
    "info@cncf.io",
    "info@rook.io",
    "infra-root@openstack.org",
    "jaegerci-bot@users.noreply.github.com",
    "jenkins-x-bot-test@users.noreply.github.com",
    "jenkins-x-bot@users.noreply.github.com",
    "jenkins@doi-janky.infosiftr.net",
    "jenkins@openstack.org",
    "jenkins@review.openstack.org",
    "k8s-cherrypick-bot@users.noreply.github.com",
    "k8s-merge-robot@users.noreply.github.com",
    "k8s-publish-robot@users.noreply.github.com",
    "k8s.production.user@gmail.com",
    "k8sio-netlify-preview-bot@users.noreply.github.com",
    "katacontainersbot@users.noreply.github.com",
    "kube-aws-bot@users.noreply.github.com",
    "kubernetes-bot@users.noreply.github.com",
    "mergify[bot]@users.noreply.github.com",
    "minikube-bot@google.com",
    "minikube-bot@users.noreply.github.com",
    "nfdmergebot@intel.com",
    "nobody@k8s.io",
    "openstack-infra@lists.openstack.org",
    "openstack-zuul[bot]@users.noreply.github.com",
    "prowbot@users.noreply.github.com",
    "pyup-bot@users.noreply.github.com",
    "redhat-k8s-bot@users.noreply.github.com",
    "release-bot@arangodb.com",
    "review@openstack.org",
    "rh-atomic-bot@users.noreply.github.com",
    "rh-kube-bot@users.noreply.github.com",
    "rktbot@users.noreply.github.com",
    "rmohr+kubebot@redhat.com",
    "spinbot@spinnaker.io",
    "support@dependabot.com",
    "support@greenkeeper.io",
    "tekton-robot@users.noreply.github.com",
    "zuul@openstack.org",
    "zuul@zuul.openstack.org"
]

#
# Options:
#
# -b dir	Specify the base directory to fetch the configuration files
# -c cfile	Specify a configuration file
# -d		Output individual developer stats
# -D		Output date statistics
# -h hfile	HTML output to hfile
# -l count	Maximum length for output lists
# -n            Use numstats instead of generated patch from git log
# -o file	File for text output
# -p prefix     Prefix for CSV output
# -r pattern	Restrict to files matching pattern (or not matching if used with -R)
# -R            Invert FileFilter (so it will return only files *NOT* matching -r pattern)
# -s		Ignore author SOB lines
# -u		Map unknown employers to '(Unknown)'
# -m		Map unknown employers to their email's domain name
# -U 		Dump unknown hackers in report
# -x file.csv   Export raw statistics as CSV
# -w            Aggregrate the raw statistics by weeks instead of months
# -y            Aggregrate the raw statistics by years instead of months
# -z		Dump out the hacker database at completion
# -i            Specify input file (instead of default sys.stdin)
# -X            Stop in the debugger at end (cannot be used with stdin, please use -i)
# -I file.csv   Generate per file stats
# -f date       Only use patches >= date
# -e date       Only use patches <= date

def ParseOpts ():
    global MapUnknown, DevReports, FileStats
    global DateStats, AuthorSOBs, FileFilter, InvertFilter, DumpDB
    global CFName, CSVFile, CSVPrefix, DirName, Aggregate, Numstat
    global ReportByFileType, ReportUnknowns, AffFile, ReportAll
    global InputData, InputDataIsFile, DebugHalt, DateFrom, DateTo

    opts, rest = getopt.getopt (sys.argv[1:], 'a:i:I:b:dc:Dh:l:no:p:r:stAUumwx:yzXf:e:R')
    for opt in opts:
        if opt[0] == '-b':
            DirName = opt[1]
        elif opt[0] == '-c':
            CFName = opt[1]
        elif opt[0] == '-d':
            DevReports = 0
        elif opt[0] == '-D':
            DateStats = 1
        elif opt[0] == '-h':
            reports.SetHTMLOutput (open (opt[1], 'w'))
        elif opt[0] == '-l':
            reports.SetMaxList (int (opt[1]))
        elif opt[0] == '-n':
            Numstat = 1
        elif opt[0] == '-o':
            reports.SetOutput (open (opt[1], 'w'))
        elif opt[0] == '-p':
            CSVPrefix = opt[1]
        elif opt[0] == '-R':
            InvertFilter = True
        elif opt[0] == '-r':
            print 'Filter on "%s"' % (opt[1])
            FileFilter = re.compile (opt[1])
        elif opt[0] == '-s':
            AuthorSOBs = 0
        elif opt[0] == '-t':
            ReportByFileType = 1
        elif opt[0] == '-m':
            MapUnknown = 1
        elif opt[0] == '-u':
            MapUnknown = 2
        elif opt[0] == '-U':
            ReportUnknowns = True
        elif opt[0] == '-A':
            ReportAll = True
        elif opt[0] == '-I':
            FileStats = open (opt[1], 'w')
            print "Save all file statistics in " + opt[1] + "\n"
        elif opt[0] == '-x':
            CSVFile = open (opt[1], 'w')
            print "Open output file " + opt[1] + "\n"
        elif opt[0] == '-a':
            AffFile = open (opt[1], 'w')
            print "Save all affiliations in " + opt[1] + "\n"
        elif opt [0] == '-w':
            Aggregate = 'week'
        elif opt [0] == '-y':
            Aggregate = 'year'
        elif opt[0] == '-z':
            DumpDB = 1
        elif opt[0] == '-X':
            DebugHalt = True
        elif opt[0] == '-f':
            DateFrom = datetime.datetime.strptime(opt[1], '%Y-%m-%d')
        elif opt[0] == '-e':
            DateTo = datetime.datetime.strptime(opt[1], '%Y-%m-%d')
        elif opt[0] == '-i':
            try:
                InputData = open(opt[1], 'r')
                InputDataIsFile = True
            except IOError:
                print "Cannot open input file: " + opt[1] + "\n"
                sys.exit(1)

unknowns = {
    'gmail.com', 'hotmail.co.uk', 'toph.ca', 'yandex.com', 'moscar.net', 'bedafamily.com', 'ebay.com', 'hotmail.com', 'yahoo.com', 'qq.com', 'zju.edu.cn',
    'outlook.com', 
}
unknown_domains = {}
for unknown in unknowns:
    unknown_domains[unknown] = []

def LookupStoreHacker (name, email):
    email = database.RemapEmail (email)
    ha = database.LookupEmail (email)
    if ha: # already there
        return ha
    elist = database.LookupEmployer (email, MapUnknown)
    ha = database.LookupName (name)
    if email != 'unknown@hacker.net' and elist[0][1].name == '(Unknown)' and '@' in email:
        domain = email.split('@')[1].strip().lower()
        if domain in unknown_domains:
            unknown_domains[domain].append(email)
        else:
            unknown_domains[domain] = [email]
    if ha: # new email
        ha.addemail (email, elist)
        return ha
    return database.StoreHacker(name, elist, email)

def DebugUnknowns():
    global DebugHalt
    n_hackers = len(database.HackersByName.values())
    hdict = {}
    for hacker in database.HackersByName.values():
        hkey = hacker.employer[0][0][1].name
        if hkey not in hdict:
            hdict[hkey] = [hacker.email[0]]
        else:
            hdict[hkey].append(hacker.email[0])
    srt_hackers = sorted(hdict.items(), key=lambda x: -len(x[1]))
    top_hackers = map(lambda x: (x[0], len(x[1])), srt_hackers)
    srt_unknown = sorted(unknown_domains.items(), key=lambda x: -len(x[1]))
    top_unknown = map(lambda x: (x[0], len(x[1])), srt_unknown)
    srt_adomains = sorted(database.ArtificialDomains.items(), key=lambda x: -len(x[1]))
    top_adomains = map(lambda x: (x[0], len(x[1])), srt_adomains)
    if DebugHalt:
        pdb.set_trace()

#
# Date tracking.
#

DateMap = { }

def AddDateLines(date, lines):
    if lines > 20000000:
        print 'Skip big patch (%d)' % lines
        return
    try:
        DateMap[date] += lines
    except KeyError:
        DateMap[date] = lines

def PrintDateStats():
    dates = DateMap.keys ()
    dates.sort ()
    total = 0
    datef = open ('datelc.csv', 'w')
    datef.write('Date,Changed,Total Changed\n')
    for date in dates:
        total += DateMap[date]
        datef.write ('%d/%02d/%02d,%d,%d\n' % (date.year, date.month, date.day,
                                    DateMap[date], total))


#
# Let's slowly try to move some smarts into this class.
#
class patch:
    (ADDED, REMOVED) = range (2)

    def __init__ (self, commit):
        self.commit = commit
        self.merge = self.added = self.removed = 0
        self.author = LookupStoreHacker('Unknown hacker', 'unknown@hacker.net')
        self.email = 'unknown@hacker.net'
        self.sobs = [ ]
        self.reviews = [ ]
        self.testers = [ ]
        self.reports = [ ]
        self.filetypes = {}
        self.files = {}
        self.totaled = False

    def addreviewer (self, reviewer):
        self.reviews.append (reviewer)

    def addtester (self, tester):
        self.testers.append (tester)

    def addreporter (self, reporter):
        self.reports.append (reporter)

    def addfiletype (self, filetype, added, removed):
        if self.filetypes.has_key (filetype):
            self.filetypes[filetype][self.ADDED] += added
            self.filetypes[filetype][self.REMOVED] += removed
        else:
            self.filetypes[filetype] = [added, removed]

    def addfile (self, filename, added, removed):
            self.files[filename] = [added, removed, max(added, removed)]

    def repr (self):
        return ('Patch', self.commit, self.author.repr(), 'Email', self.email)

ns = {'n': 0 }
for key in patterns.keys():
    ns[key] = 0

def parse_numstat(line, file_filter):
    global ns, InvertFilter
    """
        Receive a line of text, determine if fits a numstat line and
        parse the added and removed lines as well as the file type.
    """
    m = patterns['numstat'].match (line)
    ns['n'] += 1
    if m:
        if 'numstat' not in ns:
            ns['numstat'] = 1
        else:
            ns['numstat'] += 1

        filename = m.group (3)
        # If we have a file filter, check for file lines.
        if file_filter:
            match = not not file_filter.search(filename)
            # print(filename)
            if match == InvertFilter:
                return None, None, None, None

        try:
            added = int (m.group (1))
            removed = int (m.group (2))
        except ValueError:
            # A binary file (image, etc.) is marked with '-'
            added = removed = 0

        m = patterns['rename'].match (filename)
        if m:
            filename = '%s%s%s' % (m.group (1), m.group (3), m.group (4))
            if 'rename' not in ns:
                ns['rename'] = 1
            else:
                ns['rename'] += 1

        filetype = database.FileTypes.guess_file_type (os.path.basename(filename))
        return filename, filetype, added, removed
    else:
        return None, None, None, None

def is_botemail(email):
    global BotEmails
    return email in BotEmails

#
# The core hack for grabbing the information about a changeset.
#
matched = { 'n': 0 }
for key in patterns.keys():
    matched[key] = 0

def grabpatch(logpatch):
    global matched, FileStats

    matched['n'] += 1
    # just to exclude invalid patterns (not suited for non openstack repo - kubernetes)
    m = patterns['commit'].match (logpatch[0])
    if not m:
        return None
    matched['commit'] += 1

    pa = patch(m.group (1))
    ignore = (FileFilter is not None)
    for Line in logpatch[1:]:
        #
        # Maybe it's an author line?
        #
        m = patterns['author'].match (Line)
        if m:
            pa.email = database.RemapEmail (m.group (2))
            if not is_botemail(pa.email):
                pa.author = LookupStoreHacker(m.group (1), pa.email)
            else:
                return 'bot'
            dkey = 'author'
            if dkey not in matched:
                matched[dkey] = 1
            else:
                matched[dkey] += 1
            continue
        #
        # Could be a signed-off-by:
        #
        m = patterns['signed-off-by'].match (Line)
        if m:
            email = database.RemapEmail (m.group (2))
            sobber = LookupStoreHacker(m.group (1), email)
            if sobber != pa.author or AuthorSOBs:
                pa.sobs.append ((email, LookupStoreHacker(m.group (1), m.group (2))))
            dkey = 'signed-off-by'
            if dkey not in matched:
                matched[dkey] = 1
            else:
                matched[dkey] += 1
            continue
        #
        # Various other tags of interest.
        #
        m = patterns['reviewed-by'].match (Line)
        if m:
            email = database.RemapEmail (m.group (2))
            pa.addreviewer (LookupStoreHacker(m.group (1), email))
            dkey = 'reviewed-by'
            if dkey not in matched:
                matched[dkey] = 1
            else:
                matched[dkey] += 1
            continue
        m = patterns['tested-by'].match (Line)
        if m:
            email = database.RemapEmail (m.group (2))
            pa.addtester (LookupStoreHacker (m.group (1), email))
            pa.author.testcredit (patch)
            dkey = 'tested-by'
            if dkey not in matched:
                matched[dkey] = 1
            else:
                matched[dkey] += 1
            continue
        # Reported-by:
        m = patterns['reported-by'].match (Line)
        if m:
            email = database.RemapEmail (m.group (2))
            pa.addreporter (LookupStoreHacker (m.group (1), email))
            pa.author.reportcredit (patch)
            dkey = 'reported-by'
            if dkey not in matched:
                matched[dkey] = 1
            else:
                matched[dkey] += 1
            continue
        # Reported-and-tested-by:
        m = patterns['reported-and-tested-by'].match (Line)
        if m:
            email = database.RemapEmail (m.group (2))
            h = LookupStoreHacker (m.group (1), email)
            pa.addreporter (h)
            pa.addtester (h)
            pa.author.reportcredit (patch)
            pa.author.testcredit (patch)
            dkey = 'reported-and-tested-by'
            if dkey not in matched:
                matched[dkey] = 1
            else:
                matched[dkey] += 1
            continue
        #
        # If this one is a merge, make note of the fact.
        #
        m = patterns['merge'].match (Line)
        if m:
            pa.merge = 1
            dkey = 'merge'
            if dkey not in matched:
                matched[dkey] = 1
            else:
                matched[dkey] += 1
            continue
        #
        # See if it's the date.
        #
        m = patterns['date'].match (Line)
        if m:
            dt = rfc822.parsedate(m.group (2))
            pa.date = datetime.date (dt[0], dt[1], dt[2])
            if pa.date > Today:
                sys.stderr.write ('Funky date: %s\n' % pa.date)
                pa.date = Today
            dkey = 'date'
            if dkey not in matched:
                matched[dkey] = 1
            else:
                matched[dkey] += 1
            continue
        if not Numstat:
            #
            # If we have a file filter, check for file lines.
            #
            if FileFilter:
                ignore = ApplyFileFilter (Line, ignore)
                if InvertFilter:
                    ignore = not ignore
            #
            # OK, maybe it's part of the diff itself.
            #
            if not ignore:
                if patterns['add'].match (Line):
                    pa.added += 1
                    dkey = 'add'
                    if dkey not in matched:
                        matched[dkey] = 1
                    else:
                        matched[dkey] += 1
                    continue
                if patterns['rem'].match (Line):
                    dkey = 'rem'
                    if dkey not in matched:
                        matched[dkey] = 1
                    else:
                        matched[dkey] += 1
                    pa.removed += 1
        else:
            # Get the statistics (lines added/removes) using numstats
            # and without requiring a diff (--numstat instead -p)
            (filename, filetype, added, removed) = parse_numstat (Line, FileFilter)
	    if filename:
	        pa.added += added
		pa.removed += removed
		pa.addfiletype (filetype, added, removed)
                if FileStats:
		    pa.addfile (filename, added, removed)

    if '@' in pa.author.name:
        GripeAboutAuthorName (pa.author.name)

    return pa

def GripeAboutAuthorName (name):
    if name in GripedAuthorNames:
        return
    GripedAuthorNames.append (name)
    print email_encode('%s is an author name, probably not what you want' % (name))

def ApplyFileFilter (line, ignore):
    #
    # If this is the first file line (--- a/), set ignore one way
    # or the other.
    #
    m = patterns['filea'].match (line)
    if m:
        file = m.group (1)
        if FileFilter.search (file):
            return 0
        return 1
    #
    # For the second line, we can turn ignore off, but not on
    #
    m = patterns['fileb'].match (line)
    if m:
        file = m.group (1)
        if FileFilter.search (file):
            return 0
    return ignore

def is_svntag(logpatch):
    """
        This is a workaround for a bug on the migration to Git
        from Subversion found in GNOME.  It may happen in other
        repositories as well.
    """

    for Line in logpatch:
        m = patterns['svn-tag'].match(Line.strip())
        if m:
            sys.stderr.write ('(W) detected a commit on a svn tag: %s\n' %
                              (m.group (0),))
            return True

    return False


#
# Here starts the real program.
#
ParseOpts ()

#
# Read the config files.
#
ConfigFile.ConfigFile (CFName, DirName)

TotalChanged = TotalAdded = TotalRemoved = 0

#
# Snarf changesets.
#
print >> sys.stderr,  str(DateFrom) + ' - ' + str(DateTo) + '\r'
print >> sys.stderr, 'Grabbing changesets...\r'

patches = logparser.LogPatchSplitter(InputData, DateFrom, DateTo)
printcount = CSCount = 0

for logpatch in patches:
    if (printcount % 10) == 0:
        print >> sys.stderr, 'Grabbing changesets...%d\r' % printcount,
    printcount += 1

    # We want to ignore commits on svn tags since in Subversion
    # thats mean a copy of the whole repository, which leads to
    # wrong results.  Some migrations from Subversion to Git does
    # not catch all this tags/copy and import them just as a new
    # big changeset.
    if is_svntag(logpatch):
        continue

    pa = grabpatch(logpatch)
    if not pa:
        break
    #
    # skip over any Bots
    #
    if pa == 'bot':
        continue

#    if pa.added > 100000 or pa.removed > 100000:
#        print 'Skipping massive add', pa.commit
#        continue
    if FileFilter and pa.added == 0 and pa.removed == 0:
        continue

    #
    # Record some global information - but only if this patch had
    # stuff which wasn't ignored.
    #
    if ((pa.added + pa.removed) > 0 or not FileFilter) and not pa.merge:
        TotalAdded += pa.added
        TotalRemoved += pa.removed
        TotalChanged += max (pa.added, pa.removed)
        pa.totaled = True
        AddDateLines (pa.date, max (pa.added, pa.removed))
        empl = pa.author.emailemployer (pa.email, pa.date)
        if not empl:
            # Usually missing the final affiliation (like last affiliation ws untin 2019-01-01 and this patch is from 2019-03-03
            print 'pdb on email ', pa.email
            print 'pdb on logpatch ', logpatch
            pdb.set_trace()
            continue
        empl.AddCSet (pa)
        for sobemail, sobber in pa.sobs:
            empl = sobber.emailemployer (sobemail, pa.date)
            empl.AddSOB()

    if not pa.merge:
        pa.author.addpatch (pa)
        for sobemail, sob in pa.sobs:
            sob.addsob (pa)
        for hacker in pa.reviews:
            hacker.addreview (pa)
        for hacker in pa.testers:
            hacker.addtested (pa)
        for hacker in pa.reports:
            hacker.addreport (pa)
        CSCount += 1
    csvdump.AccumulatePatch (pa, Aggregate)
    csvdump.store_patch (pa)
print >> sys.stderr, 'Grabbing changesets...done       '

if DumpDB:
    database.DumpDB ()
database.MixVirtuals ()

# See: database.Employers
DebugUnknowns()

#
# Say something
#
hlist = database.AllHackers ()
elist = database.AllEmployers ()
# 'erick@fejta.com' in set(sum(map(lambda el: el.email, hlist), []))
# sum(map(lambda el: el.email, hlist), [])
# pdb.set_trace()
ndev = nempl = 0
for h in hlist:
    if len (h.patches) > 0:
        ndev += 1
for e in elist:
    if e.count > 0:
        nempl += 1
reports.Write ('Processed %d csets from %d developers\n' % (CSCount,
                                                            ndev))
reports.Write ('%d employers found\n' % (nempl))
reports.Write ('A total of %d lines added, %d removed, %d changed (delta %d)\n' %
               (TotalAdded, TotalRemoved, TotalChanged, TotalAdded - TotalRemoved))
if TotalChanged == 0:
    TotalChanged = 1 # HACK to avoid div by zero
if DateStats:
    PrintDateStats ()

if CSVPrefix:
    csvdump.save_csv (CSVPrefix)

if CSVFile:
    csvdump.OutputCSV (CSVFile)
    CSVFile.close ()

if AffFile:
    database.AllAffsCSV(AffFile, hlist)
    AffFile.close()

if FileStats:
    database.AllFilesCSV(FileStats, hlist, FileFilter, InvertFilter)
    FileStats.close()

if DevReports:
    reports.DevReports (hlist, TotalChanged, CSCount, TotalRemoved)
if ReportUnknowns:
    reports.ReportUnknowns(hlist, CSCount)
    reports.ReportSelfs(hlist, CSCount)
if ReportAll:
    reports.ReportAll(hlist, CSCount)
reports.EmplReports (elist, TotalChanged, CSCount)

if ReportByFileType and Numstat:
    reports.ReportByFileType (hlist)

if InputDataIsFile:
    InputData.close()
