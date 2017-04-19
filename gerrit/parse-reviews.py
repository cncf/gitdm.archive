import argparse
import json
import sys
import time

#
# List reviewers for a set of git commits
#
#  python buglist.py essex-commits.txt openstack-config/launchpad-ids.txt < gerrit.json
#

parser = argparse.ArgumentParser(description='List reviewers in gerrit')

parser.add_argument('commits', help='path to list of commits to consider')
parser.add_argument('usermap', help='path to username to email map')

args = parser.parse_args()

username_to_email_map = {}
for l in open(args.usermap, 'r'):
    (username, email) = l.split()
    username_to_email_map.setdefault(username, email)

commits = [l.strip() for l in open(args.commits, 'r')]

class Reviewer:
    def __init__(self, username, name, email):
        self.username = username
        self.name = name
        self.email = email if email else username_to_email_map.get(self.username)

    @classmethod
    def parse(cls, r):
        return cls(r.get('username'), r.get('name'), r.get('email'))

class Approval:
    CodeReviewed, Approved, Submitted, Verified, Workflow = range(5)

    type_map = {
        'Code-Review': CodeReviewed,
        'Approved': Approved,
        'SUBM': Submitted,
        'Verified': Verified,
        'Workflow': Workflow,
        }

    def __init__(self, type, value, date, by):
        self.type = type
        self.value = value
        self.date = date
        self.by = by

    @classmethod
    def parse(cls, a):
        return cls(cls.type_map[a['type']],
                   int(a['value']),
                   time.gmtime(int(a['grantedOn'])),
                   Reviewer.parse(a['by']))

class PatchSet:
    def __init__(self, revision, approvals):
        self.revision = revision
        self.approvals = approvals

    @classmethod
    def parse(cls, ps):
        return cls(ps['revision'],
                   [Approval.parse(a) for a in ps.get('approvals', [])])

class Review:
    def __init__(self, id, patchsets):
        self.id = id
        self.patchsets = patchsets

    @classmethod
    def parse(cls, r):
        return cls(r['id'],
                   [PatchSet.parse(ps) for ps in r['patchSets']])

reviews = [Review.parse(json.loads(l)) for l in sys.stdin if not 'runTimeMilliseconds' in l]

def reviewers(review):
    ret = {}
    for ps in r.patchsets:
        for a in ps.approvals:
            if a.type == Approval.CodeReviewed and a.value:
                ret.setdefault(a.by.username, (a.by, a.date))
    return ret.values()

def interesting(review):
    for ps in r.patchsets:
        if ps.revision in commits:
            return True
    return False

for r in reviews:
    if not interesting(r):
        continue
    for reviewer, date in reviewers(r):
        if reviewer.email:
            print time.strftime('%Y-%m-%d', date), reviewer.username, reviewer.email
