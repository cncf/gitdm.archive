#
# A new home for the reporting code.
#
# This code is part of the LWN git data miner.
#
# Copyright 2007-12 Eklektix, Inc.
# Copyright 2007-12 Jonathan Corbet <corbet@lwn.net>
#
# This file may be distributed under the terms of the GNU General
# Public License, version 2.
#

import sys
import pdb
from patterns import email_encode

Outfile = sys.stdout
HTMLfile = None
ListCount = 999999


def SetOutput (file):
    global Outfile
    Outfile = file

def SetHTMLOutput (file):
    global HTMLfile
    HTMLfile = file

def SetMaxList (max):
    global ListCount
    ListCount = max


def Write (stuff):
    Outfile.write (email_encode(stuff))


def Pct(a, b):
    if b == 0:
        return 0.0
    else:
        return (a*100.0)/b

#
# HTML output support stuff.
#
HTMLclass = 0
HClasses = ['Even', 'Odd']

THead = '''<p>
<table cellspacing=3>
<tr><th colspan=3>%s</th></tr>
'''

def BeginReport (title):
    global HTMLclass
    
    Outfile.write ('\n%s\n' % title)
    if HTMLfile:
        HTMLfile.write (THead % title)
        HTMLclass = 0

TRow = '''    <tr class="%s">
<td>%s</td><td align="right">%d</td><td align="right">%.1f%%</td></tr>
'''

TRowStr = '''    <tr class="%s">
<td>%s</td><td align="right">%d</td><td>%s</td></tr>
'''

def ReportLine (text, count, pct):
    global HTMLclass
    if count == 0:
        return
    Outfile.write(email_encode('%-80s %4d (%.1f%%)\n' % (text, count, pct)))
    if HTMLfile:
        HTMLfile.write(email_encode(TRow % (HClasses[HTMLclass], text, count, pct)))
        HTMLclass ^= 1

def ReportLineStr (text, count, extra):
    global HTMLclass
    if count == 0:
        return
    Outfile.write(email_encode('%-80s %4d %s\n' % (text, count, extra)))
    if HTMLfile:
        HTMLfile.write(email_encode(TRowStr % (HClasses[HTMLclass], text, count, extra)))
        HTMLclass ^= 1

def EndReport (text=None):
    if text:
        Outfile.write(email_encode('%s\n' % (text, )))
    if HTMLfile:
        HTMLfile.write('</table>\n\n')
        
#
# Comparison and report generation functions.
#
def ComparePCount (h1, h2):
    return len (h2.patches) - len (h1.patches)

def ReportByPCount (hlist, cscount):
    hlist.sort (ComparePCount)
    count = reported = 0
    BeginReport ('Developers with the most changesets')
    for h in hlist:
        pcount = len (h.patches)
        changed = max(h.added, h.removed)
        delta = h.added - h.removed
        if pcount > 0:
            ReportLine (h.full_name_with_aff(), pcount, Pct(pcount, cscount))
            reported += pcount
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of changesets' % (Pct(reported, cscount), ))

def CompareBCount (h1, h2):
    return len (h2.bugsfixed) - len (h1.bugsfixed)

def ReportByBCount (hlist, totalbugs):
    hlist.sort (CompareBCount)
    count = reported = 0
    BeginReport ('Developers with the most bugs fixed')
    for h in hlist:
        bcount = len (h.bugsfixed)
        if bcount > 0:
            ReportLine (h.full_name_with_aff(), bcount, Pct(bcount, totalbugs))
            reported += bcount
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of bugs' % Pct(reported, totalbugs))

def CompareLChanged (h1, h2):
    return max(h2.added, h2.removed) - max(h1.added, h1.removed)

def ReportByLChanged (hlist, totalchanged):
    hlist.sort (CompareLChanged)
    count = reported = 0
    BeginReport ('Developers with the most changed lines')
    for h in hlist:
        pcount = len (h.patches)
        changed = max(h.added, h.removed)
        delta = h.added - h.removed
        if (h.added + h.removed) > 0:
            ReportLine (h.full_name_with_aff(), changed, Pct(changed, totalchanged))
            reported += changed
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of changes' % (Pct(reported, totalchanged), ))
            
def CompareLRemoved (h1, h2):
    return (h2.removed - h2.added) - (h1.removed - h1.added)

def ReportByLRemoved (hlist, totalremoved):
    hlist.sort (CompareLRemoved)
    count = reported = 0
    BeginReport ('Developers with the most lines removed')
    for h in hlist:
        pcount = len (h.patches)
        changed = max(h.added, h.removed)
        delta = h.added - h.removed
        if delta < 0:
            ReportLine (h.full_name_with_aff(), -delta, Pct(-delta, totalremoved))
            reported += -delta
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of changes' % (Pct(reported, totalremoved), ))

def CompareEPCount (e1, e2):
    return e2.count - e1.count

def ReportByPCEmpl (elist, cscount):
    elist.sort (CompareEPCount)
    count = total_pcount = 0
    BeginReport ('Top changeset contributors by employer')
    for e in elist:
        if e.count != 0:
            ReportLine (e.full_name(), e.count, Pct(e.count, cscount))
            total_pcount += e.count
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of changesets' % (Pct(total_pcount, cscount), ))

def CompareEBCount (e1, e2):
    return len (e2.bugsfixed) - len (e1.bugsfixed)

def ReportByBCEmpl (elist, totalbugs):
    elist.sort (CompareEBCount)
    count = reported = 0
    BeginReport ('Top bugs fixed by employer')
    for e in elist:
        if len(e.bugsfixed) != 0:
            ReportLine (e.full_name(), len(e.bugsfixed), Pct(len(e.bugsfixed), totalbugs))
            reported += len(e.bugsfixed)
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of bugs' % (Pct(reported, totalbugs, )))

def CompareELChanged (e1, e2):
    return e2.changed - e1.changed

def ReportByELChanged (elist, totalchanged):
    elist.sort (CompareELChanged)
    count = reported = 0
    BeginReport ('Top lines changed by employer')
    for e in elist:
        if e.changed != 0:
            ReportLine (e.full_name(), e.changed, Pct(e.changed, totalchanged))
            reported += e.changed
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of changes' % (Pct(reported, totalchanged), ))



def CompareSOBs (h1, h2):
    return len (h2.signoffs) - len (h1.signoffs)

def ReportBySOBs (hlist):
    hlist.sort (CompareSOBs)
    totalsobs = 0
    for h in hlist:
        totalsobs += len (h.signoffs)
    count = reported = 0
    BeginReport ('Developers with the most signoffs (total %d)' % totalsobs)
    for h in hlist:
        scount = len (h.signoffs)
        if scount > 0:
            ReportLine (h.full_name_with_aff(), scount, Pct(scount, totalsobs))
            reported += scount
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of signoffs' % (Pct(reported, totalsobs), ))

#
# Reviewer reporting.
#
def CompareRevs (h1, h2):
    return len (h2.reviews) - len (h1.reviews)

def ReportByRevs (hlist):
    hlist.sort (CompareRevs)
    totalrevs = 0
    for h in hlist:
        totalrevs += len (h.reviews)
    count = reported = 0
    BeginReport ('Developers with the most reviews (total %d)' % totalrevs)
    for h in hlist:
        scount = len (h.reviews)
        if scount > 0:
            ReportLine (h.full_name_with_aff(), scount, Pct(scount, totalrevs))
            reported += scount
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of reviews' % (Pct(reported, totalrevs), ))

def CompareRevsEmpl (e1, e2):
    return len (e2.reviews) - len (e1.reviews)

def ReportByRevsEmpl (elist):
    elist.sort (CompareRevsEmpl)
    totalrevs = 0
    for e in elist:
        totalrevs += len (e.reviews)
    count = reported = 0
    BeginReport ('Top reviewers by employer (total %d)' % totalrevs)
    for e in elist:
        scount = len (e.reviews)
        if scount > 0:
            ReportLine (e.full_name(), scount, Pct(scount, totalrevs))
            reported += scount
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of reviews' % (Pct(reported, totalrevs), ))

#
# tester reporting.
#
def CompareTests (h1, h2):
    return len (h2.tested) - len (h1.tested)

def ReportByTests (hlist):
    hlist.sort (CompareTests)
    totaltests = 0
    for h in hlist:
        totaltests += len (h.tested)
    count = reported = 0
    BeginReport ('Developers with the most test credits (total %d)' % totaltests)
    for h in hlist:
        scount = len (h.tested)
        if scount > 0:
            ReportLine (h.full_name_with_aff(), scount, Pct(scount, totaltests))
            reported += scount
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of test credits' % (Pct(reported, totaltests), ))

def CompareTestCred (h1, h2):
    return h2.testcred - h1.testcred

def ReportByTestCreds (hlist):
    hlist.sort (CompareTestCred)
    totaltests = 0
    for h in hlist:
        totaltests += h.testcred
    count = reported = 0
    BeginReport ('Developers who gave the most tested-by credits (total %d)' % totaltests)
    for h in hlist:
        if h.testcred > 0:
            ReportLine (h.full_name_with_aff(), h.testcred, Pct(h.testcred, totaltests))
            reported += h.testcred
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of test credits' % (Pct(reported, totaltests), ))



#
# Reporter reporting.
#
def CompareReports (h1, h2):
    return len (h2.reports) - len (h1.reports)

def ReportByReports (hlist):
    hlist.sort (CompareReports)
    totalreps = 0
    for h in hlist:
        totalreps += len (h.reports)
    count = reported = 0
    BeginReport ('Developers with the most report credits (total %d)' % totalreps)
    for h in hlist:
        scount = len (h.reports)
        if scount > 0:
            ReportLine (h.full_name_with_aff(), scount, Pct(scount, totalreps))
            report += scount
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of report credits' % (Pct(reported, totalreps), ))

def CompareRepCred (h1, h2):
    return h2.repcred - h1.repcred

def ReportByRepCreds (hlist):
    hlist.sort (CompareRepCred)
    totalreps = 0
    for h in hlist:
        totalreps += h.repcred
    count = reported = 0
    BeginReport ('Developers who gave the most report credits (total %d)' % totalreps)
    for h in hlist:
        if h.repcred > 0:
            ReportLine (h.full_name_with_aff(), h.repcred, Pct(h.repcred, totalreps))
            reported += h.repcred
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of report credits' % (Pct(reported, totalreps), ))

#
# Versions.
#
def CompareVersionCounts (h1, h2):
    if h1.versions and h2.versions:
        return len (h2.versions) - len (h1.versions)
    if h2.versions:
        return 1
    if h1.versions:
        return -1
    return 0

def MissedVersions (hv, allv):
    missed = [v for v in allv if v not in hv]
    missed.reverse ()
    return ' '.join (missed)

def ReportVersions (hlist):
    hlist.sort (CompareVersionCounts)
    BeginReport ('Developers represented in the most kernel versions')
    count = 0
    allversions = hlist[0].versions
    for h in hlist:
        ReportLineStr (h.full_name_with_aff(), len (h.versions), MissedVersions (h.versions, allversions))
        count += 1
        if count >= ListCount:
            break
    EndReport ()


def CompareESOBs (e1, e2):
    return e2.sobs - e1.sobs

def ReportByESOBs (elist):
    elist.sort (CompareESOBs)
    totalsobs = 0
    for e in elist:
        totalsobs += e.sobs
    count = reported = 0
    BeginReport ('Employers with the most signoffs (total %d)' % totalsobs)
    for e in elist:
        if e.sobs > 0:
            ReportLine (e.full_name(), e.sobs, Pct(e.sobs, totalsobs))
            reported += e.sobs
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of signoffs' % (Pct(reported, totalsobs), ))
   
def CompareHackers (e1, e2):
    return len (e2.hackers) - len (e1.hackers)

def ReportByEHackers (elist):
    elist.sort (CompareHackers)
    totalhackers = 0
    for e in elist:
        totalhackers += len (e.hackers)
    count = reported = 0
    BeginReport ('Employers with the most hackers (total %d)' % totalhackers)
    for e in elist:
        nhackers = len (e.hackers)
        if nhackers > 0:
            ReportLine (e.full_name(), nhackers, Pct(nhackers, totalhackers))
            reported += nhackers
        count += 1
        if count >= ListCount:
            break
    EndReport ('Covers %f%% of hackers' % (Pct(reported, totalhackers), ))


def DevReports (hlist, totalchanged, cscount, totalremoved):
    ReportByPCount (hlist, cscount)
    ReportByLChanged (hlist, totalchanged)
    ReportByLRemoved (hlist, totalremoved)
    # LG: I've uncommented this to see if it works
    ReportBySOBs (hlist)
    ReportByRevs (hlist)
    ReportByTests (hlist)
    ReportByTestCreds (hlist)
    ReportByReports (hlist)
    ReportByRepCreds (hlist)

def EmplReports (elist, totalchanged, cscount):
    ReportByPCEmpl (elist, cscount)
    ReportByELChanged (elist, totalchanged)
    ReportByESOBs (elist)   # LG: uncommented
    ReportByEHackers (elist)

def DevBugReports (hlist, totalbugs):
    ReportByBCount (hlist, totalbugs)

def EmplBugReports (elist, totalbugs):
    ReportByBCEmpl (elist, totalbugs)

def DevReviews (hlist, totalreviews):
    ReportByRevs (hlist)

def EmplReviews (elist, totalreviews):
    ReportByRevsEmpl (elist)

#
# Who are the unknown hackers?
#
def IsUnknown(h):
    # LG: need to take a look
    empl = h.employer[0][0][1].name
    return h.email[0] == empl or empl == '(Unknown)' or empl == 'NotFound'

def IsSelf(h):
    empl = h.employer[0][0][1].name
    return empl == 'Independent'

def ReportAll(hlist, cscount):
    ulist = hlist
    ulist.sort(ComparePCount)
    count = 0
    BeginReport('All developers')
    alldevsFile = open('alldevs.txt', 'w')
    for h in ulist:
        pcount = len(h.patches)
        if pcount > 0:
            ReportLine(h.full_name_with_aff(), pcount, (pcount*100.0)/cscount)
            alldevsFile.write(email_encode('%s\t%d\n' % (h.full_name_with_aff_tabs(), pcount)))
            count += 1
        if count >= ListCount:
            break
    alldevsFile.close()
    EndReport()

def ReportUnknowns(hlist, cscount):
    #
    # Trim the list to just the unknowns; try to work properly whether
    # mapping to (Unknown) is happening or not.
    #
    ulist = [ h for h in hlist if IsUnknown(h) ]
    ulist.sort(ComparePCount)
    count = 0
    BeginReport('Developers with unknown affiliation')
    unknownsFile = open('unknowns.txt', 'w')
    for h in ulist:
        pcount = len(h.patches)
        if pcount > 0:
            ReportLine(h.full_name_with_aff(), pcount, (pcount*100.0)/cscount)
            unknownsFile.write(email_encode('%s\t%d\n' % (h.full_name_with_aff_tabs(), pcount)))
            count += 1
        if count >= ListCount:
            break
    unknownsFile.close()
    EndReport()

def ReportSelfs(hlist, cscount):
    ulist = [ h for h in hlist if IsSelf(h) ]
    ulist.sort(ComparePCount)
    count = 0
    BeginReport('Developers working on their own behalf')
    for h in ulist:
        pcount = len(h.patches)
        if pcount > 0:
            ReportLine(h.full_name_with_aff(), pcount, (pcount*100.0)/cscount)
            count += 1
        if count >= ListCount:
            break
    EndReport()

def ReportByFileType (hacker_list):
    total = {}
    total_by_hacker = {}

    BeginReport ('Developer contributions by type')
    for h in hacker_list:
        by_hacker = {}
        for patch in h.patches:
            # Get a summary by hacker
            for (filetype, (added, removed)) in patch.filetypes.iteritems():
                if by_hacker.has_key(filetype):
                    by_hacker[filetype][patch.ADDED] += added
                    by_hacker[filetype][patch.REMOVED] += removed
                else:
                    by_hacker[filetype] = [added, removed]

                # Update the totals
                if total.has_key(filetype):
                    total[filetype][patch.ADDED] += added
                    total[filetype][patch.REMOVED] += removed
                else:
                    total[filetype] = [added, removed, []]

        # Print a summary by hacker
        print email_encode(h.full_name_with_aff())
        for filetype, counters in by_hacker.iteritems():
            print '\t', filetype, counters
            h_added = by_hacker[filetype][patch.ADDED]
            h_removed = by_hacker[filetype][patch.REMOVED]
            total[filetype][2].append ([h.full_name_with_aff(), h_added, h_removed])

    # Print the global summary
    BeginReport ('Contributions by type and developers')
    for filetype, (added, removed, hackers) in total.iteritems():
        print filetype, added, removed
        for h, h_added, h_removed in hackers:
            print email_encode('\t%s: [%d, %d]' % (h, h_added, h_removed))

    # Print the very global summary
    BeginReport ('General contributions by type')
    for filetype, (added, removed, hackers) in total.iteritems():
        print filetype, added, removed
