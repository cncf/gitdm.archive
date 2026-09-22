#
# The "database".
#
# This code is part of the LWN git data miner.
#
# Copyright 2007-11 Eklektix, Inc.
# Copyright 2007-11 Jonathan Corbet <corbet@lwn.net>
#
# This file may be distributed under the terms of the GNU General
# Public License, version 2.
#
import sys, datetime
import pdb
import csv
from patterns import email_encode

class Hacker:
    def __init__ (self, name, id, elist, email):
        self.name = name
        self.id = id
        self.employer = [ elist ]
        self.email = [ email ]
        self.added = self.removed = 0
        self.patches = [ ]
        self.signoffs = [ ]
        self.reviews = [ ]
        self.tested = [ ]
        self.reports = [ ]
        self.bugsfixed = [ ]
        self.testcred = self.repcred = 0
        self.versions = [ ]
        if elist[0][2]:
            self.source = 'domain'
        else:
            self.source = 'config'

    def full_name(self):
        return self.email[0] + ' ' + self.name

    def full_name_with_aff(self):
        return self.employer[0][0][1].name + ' ' + self.email[0] + ' ' + self.name

    def full_name_with_aff_tabs(self):
        return self.employer[0][0][1].name + '\t' + self.email[0] + '\t' + self.name

    def repr(self):
        return ('Hacker', self.id, self.name, 'Email', self.email[0], 'Employers', len(self.employer))

    def addemail (self, email, elist):
        self.email.append (email)
        self.employer.append (elist)
        HackersByEmail[email] = self

    def emailemployer (self, email, date):
        for i in range (0, len (self.email)):
            if self.email[i] == email:
                for edate, empl, dom in self.employer[i]:
                    if edate > date:
                        return empl
        # pdb.set_trace()
        # If there is a circular alias - this bug will appear!
        print 'OOPS.  ', self.name, self.employer, self.email, email, date
        return None # Should not happen

    def addpatch (self, patch):
        self.added += patch.added
        self.removed += patch.removed
        self.patches.append (patch)

    #
    # Note that the author is represented in this release.
    #
    def addversion (self, release):
        if release not in self.versions:
            self.versions.append (release)
    #
    # There's got to be a better way.
    #
    def addsob (self, patch):
        self.signoffs.append (patch)
    def addreview (self, patch):
        self.reviews.append (patch)
    def addtested (self, patch):
        self.tested.append (patch)
    def addreport (self, patch):
        self.reports.append (patch)

    def reportcredit (self, patch):
        self.repcred += 1
    def testcredit (self, patch):
        self.testcred += 1

    def addbugfixed (self, bug):
        self.bugsfixed.append (bug)

HackersByName = { }
HackersByEmail = { }
HackersByID = { }
MaxID = 0

def StoreHacker (name, elist, email):
    global MaxID

    id = MaxID
    MaxID += 1
    h = Hacker (name, id, elist, email)
    HackersByName[name] = h
    HackersByEmail[email] = h
    HackersByID[id] = h
    return h

def LookupEmail (addr):
    try:
        return HackersByEmail[addr]
    except KeyError:
        return None

def LookupName (name):
    try:
        return HackersByName[name]
    except KeyError:
        return None

def LookupID (id):
    try:
        return HackersByID[id]
    except KeyError:
        return None

def ReverseAlias(email):
    if not email in EmailAliases.values():
        return []
    return [em_key for em_key, em_val in EmailAliases.items() if em_val == email and em_key != email]

def AllFilesCSV(file, hlist, FileFilter, InvertFilter):
    if file is None:
        return
    matches = {}
    processed = {}
    writer = csv.writer (file, quoting=csv.QUOTE_NONNUMERIC)
    writer.writerow (['email', 'name', 'date', 'affiliation', 'file', 'added', 'removed', 'changed'])
    for hacker in hlist:
        for patch in hacker.patches:
            if not patch.totaled or patch.commit in processed:
                continue
            empl = patch.author.emailemployer (patch.email, patch.date)
            email = patch.email
            aname = patch.author.name
            datestr = str(patch.date)
            emplstr = empl.name.replace ('"', '.').replace ('\\', '.')
            for (filename, filedata) in patch.files.iteritems():
                if filedata[2] == 0:
                    continue
                if FileFilter:
                    if filename in matches:
                        match = matches[filename]
                    else:
                        match = not not FileFilter.search(filename)
                        matches[filename] = match
                    if match == InvertFilter:
                        continue
                writer.writerow ([email_encode(email), email_encode(aname), datestr, emplstr, filename, filedata[0], filedata[1], filedata[2]])
            processed[patch.commit] = True

def AllAffsCSV(file, hlist):
    if file is None:
        return
    writer = csv.writer (file, quoting=csv.QUOTE_NONNUMERIC)
    writer.writerow (['email', 'name', 'company', 'date_to', 'source'])
    emails = list(set(sum(map(lambda el: el.email, hlist), [])))
    emails.sort()
    for email in emails:
        if email == 'unknown@hacker.net':
            continue
        email = RemapEmail(email)
        name = LookupEmail(email).name
        empls = MapToEmployer(email, 2)
        for date, empl, domain in empls:
            datestr = str(date)
            if date > yesterday:
                datestr = ''
            emplstr = empl.name.replace ('"', '.').replace ('\\', '.')
            source = 'config'
            if domain:
                source = 'domain'
            writer.writerow ([email_encode(email), email_encode(name), emplstr, datestr, source])
            for em in ReverseAlias(email):
                if em in emails:
                    print 'This is bad, reverse email already in emails, check: `em`, `email`, `emails`'
                    pdb.set_trace()
                writer.writerow ([email_encode(em), email_encode(name), emplstr, datestr])

def AllHackers ():
    return HackersByID.values ()
#    return [h for h in HackersByID.values ()] #  if (h.added + h.removed) > 0]

def DumpDB ():
    out = open ('database.dump', 'w')
    names = HackersByName.keys ()
    names.sort ()
    for name in names:
        h = HackersByName[name]
        out.write ('%4d %s %d p (+%d -%d) sob: %d\n' % (h.id, h.name,
                                                        len (h.patches),
                                                        h.added, h.removed,
                                                        len (h.signoffs)))
        for i in range (0, len (h.email)):
            out.write ('\t%s -> \n' % (email_encode(h.email[i])))
            for date, empl, dom in h.employer[i]:
                out.write ('\t\t %d-%d-%d %s\n' % (date.year, date.month, date.day,
                                                 empl.name))
        if h.versions:
            out.write ('\tVersions: %s\n' % ','.join (h.versions))

#
# Hack: The first visible tag comes a ways into the stream; when we see it,
# push it backward through the changes we've already seen.
#
def ApplyFirstTag (tag):
    for n in HackersByName.keys ():
        if HackersByName[n].versions:
            HackersByName[n].versions = [tag]

#
# Employer info.
#
class Employer:
    def __init__ (self, name):
        self.name = name
        self.added = self.removed = self.count = self.changed = 0
        self.sobs = 0
        self.bugsfixed = [ ]
        self.reviews = [ ]
        self.hackers = [ ]

    def full_name(self):
        return self.name

    def repr(self):
        return ('Employer', self.name, 'Hackers', len(self.hackers))

    def AddCSet (self, patch):
        self.added += patch.added
        self.removed += patch.removed
        self.changed += max(patch.added, patch.removed)
        self.count += 1
        if patch.author not in self.hackers:
            self.hackers.append (patch.author)

    def AddSOB (self):
        self.sobs += 1

    def AddBug (self, bug):
        self.bugsfixed.append(bug)
        if bug.owner not in self.hackers:
            self.hackers.append (bug.owner)

    def AddReview (self, reviewer):
        self.reviews.append(reviewer)
        if reviewer not in self.hackers:
            self.hackers.append (reviewer)

Employers = { }

def GetEmployer (name):
    if CompanyMap.has_key (name):
        name = CompanyMap[name]
    try:
        return Employers[name]
    except KeyError:
        e = Employer (name)
        Employers[name] = e
        return e

def AllEmployers ():
    return Employers.values ()

#
# Certain obnoxious developers, who will remain nameless (because we
# would never want to run afoul of Thomas) want their work split among
# multiple companies.  Let's try to cope with that.  Let's also hope
# this doesn't spread.
#
class VirtualEmployer (Employer):
    def __init__ (self, name):
        Employer.__init__ (self, name)
        self.splits = [ ]

    def addsplit (self, name, fraction):
        self.splits.append ((name, fraction))

    #
    # Go through and (destructively) apply our credits to the
    # real employer.  Only one level of weirdness is supported.
    #
    def applysplits (self):
        for name, fraction in self.splits:
            real = GetEmployer (name)
            real.added += int (self.added*fraction)
            real.removed += int (self.removed*fraction)
            real.changed += int (self.changed*fraction)
            real.count += int (self.count*fraction)
        self.__init__ (name) # Reset counts just in case

    def store (self):
        if Employers.has_key (self.name):
            print Employers[self.name]
            sys.stderr.write ('WARNING: Virtual empl %s overwrites another\n'
                              % (self.name))
        if len (self.splits) == 0:
            sys.stderr.write ('WARNING: Virtual empl %s has no splits\n'
                              % (self.name))
            # Should check that they add up too, but I'm lazy
        Employers[self.name] = self

class FileType:
    def __init__ (self, patterns={}, order=[]):
        self.patterns = patterns
        self.order = order

    def guess_file_type (self, filename, patterns=None, order=None):
        patterns = patterns or self.patterns
        order = order or self.order

        for file_type in order:
            if patterns.has_key (file_type):
                for patt in patterns[file_type]:
                    if patt.search (filename):
                        return file_type

        return 'unknown'

#
# By default we recognize nothing.
#
FileTypes = FileType ({}, [])

#
# Mix all the virtual employers into their real destinations.
#
def MixVirtuals ():
    for empl in AllEmployers ():
        if isinstance (empl, VirtualEmployer):
            empl.applysplits ()

#
# The email map.
#
EmailAliases = { }

def AddEmailAlias (variant, canonical):
    if EmailAliases.has_key (variant):
        sys.stderr.write ('Duplicate email alias for %s\n' % (email_encode(variant)))
    EmailAliases[variant] = canonical

CompanyMap = { }

def AddCompanyMap(nameFrom, nameTo):
    if CompanyMap.has_key (nameFrom):
        sys.stderr.write ('Duplicate company map for %s\n' % (nameFrom))
    CompanyMap[nameFrom] = nameTo

def RemapEmail (email):
    email = email.lower ()
    try:
        return EmailAliases[email]
    except KeyError:
        return email

#
# Email-to-employer mapping.
#
EmailToEmployer = { }
nextyear = datetime.date.today () + datetime.timedelta (days = 365)
yesterday = datetime.date.today () - datetime.timedelta(days = 1)

def AddEmailEmployerMapping (email, employer, end = nextyear, domain = False):
    if end is None:
        end = nextyear
    email = email.lower ()
    empl = GetEmployer (employer)
    try:
        l = EmailToEmployer[email]
        for i in range (0, len(l)):
            date, xempl, dom = l[i]
            if date == end:  # probably both nextyear
                print 'WARNING: duplicate email/empl for %s' % (email_encode(email))
            if date > end:
                l.insert (i, (end, empl, domain))
                return
        l.append ((end, empl, domain))
    except KeyError:
        EmailToEmployer[email] = [(end, empl, domain)]

# LG: Artificial Domains from Hacker's email domain names
ArtificialDomains = {}
def GetHackerDomain(dom, email):
    new_dom = ''.join(map(lambda x: x.lower().capitalize(), dom.split('.')[:-1]))
    new_dom += ' *'
    key = (new_dom, dom)
    if key not in ArtificialDomains:
        ArtificialDomains[key] = [email]
    else:
        ArtificialDomains[key].append(email)
    return new_dom

# LG: unknown
# 0: all Unknowns go to Employer with their name (so basically no aggregation)
# 1: all unknowns go to Company name constructed from domain name: abc@gmail.com --> Gmail
# 2: all Unknowns go to "(Unknown)" company
def MapToEmployer (email, unknown = 0):
    # Somebody sometimes does s/@/ at /; let's fix it.
    email = email.strip().lower().replace(' at ', '@')
    try:
        return EmailToEmployer[email]
    except KeyError:
        pass
    namedom = email.split ('@')
    if len (namedom) < 2:
        print 'Oops...funky email %s' % email_encode(email)
        return [(nextyear, GetEmployer ('Funky'), False)]
    s = namedom[1].split ('.')
    for dots in range (len (s) - 2, -1, -1):
        addr = '.'.join (s[dots:])
        try:
            return EmailToEmployer[addr]
        except KeyError:
            pass
    #
    # We don't know who they work for.
    #
    if unknown == 0:
        return [(nextyear, GetEmployer (email), False)]
    elif unknown == 1:
        return [(nextyear, GetEmployer (GetHackerDomain(addr, email)), False)]
    elif unknown == 2:
        return [(nextyear, GetEmployer ('(Unknown)'), False)]
    else:
        print "Unsupported unknown parameter handling value"


def LookupEmployer (email, mapunknown = 0):
    elist = MapToEmployer (email, mapunknown)
    return elist # GetEmployer (ename)

