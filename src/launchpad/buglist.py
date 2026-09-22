
#
# List all bugs marked as 'Fix Released' on a given series
#
#  python buglist.py glance essex

import argparse

parser = argparse.ArgumentParser(description='List fixed bugs for a series')

parser.add_argument('project', help='the project to act on')
parser.add_argument('series', help='the series to list fixed bugs for')

args = parser.parse_args()

from launchpadlib.launchpad import Launchpad

launchpad = Launchpad.login_with('openstack-dm', 'production')

project = launchpad.projects[args.project]
series = project.getSeries(name=args.series)

for milestone in series.all_milestones:
    for task in milestone.searchTasks(status='Fix Released'):
        assignee = task.assignee.name if task.assignee else '<unknown>'
        date = task.date_fix_committed or task.date_fix_released
        print task.bug.id, assignee, date.date()
