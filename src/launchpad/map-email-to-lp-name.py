
#
# Attempt to find a launchpad name for every email address supplied:
#
#  python map-email-to-lp-name.py foo@bar.com blaa@foo.com

import argparse

parser = argparse.ArgumentParser(description='List fixed bugs for a series')

parser.add_argument('emails', metavar='EMAIL', nargs='+',
                    help='An email address to query')

args = parser.parse_args()

from launchpadlib.launchpad import Launchpad

launchpad = Launchpad.login_with('openstack-dm', 'production')

for email in args.emails:
    try:
        person = launchpad.people.getByEmail(email=email)
        if person:
            print person.name, email
    except:
        continue
