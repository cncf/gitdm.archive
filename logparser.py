#!/usr/bin/env python
#-*- coding:utf-8 -*-
#
# Copyright © 2009 Germán Póo-Caamaño <gpoo@gnome.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA

import sys
from patterns import patterns
import datetime

class LogPatchSplitter:
    """
        LogPatchSplitters provides a iterator to extract every
        changeset from a git log output.

        Typical use case:

            patches = LogPatchSplitter(sys.stdin, datetime.date(2016,1, 1), datetime.date(2017,1,1))

            for patch in patches:
                parse_patch(patch)
    """

    def __init__(self, fd, date_from, date_to):
        self.fd = fd
        self.date_from = date_from
        self.date_to = date_to
        self.buffer = None
        self.patch = []

    def __iter__(self):
        return self

    def next(self):
        patch = self.__grab_patch__()
        while patch == "skip":
            patch = self.__grab_patch__()
        if not patch:
            raise StopIteration
        return patch

    def getDate(self, line):
        # ['Date:', '', '', 'Thu', 'May', '11', '09:15:21', '2017', '+0200\n']
        arr = line.split(' ')
        arr2 = []
        for i in range(len(arr) - 1):
            s = arr[i]
            if s != '' and s != 'Date:':
                arr2.append(s)
        datestr = ' '.join(arr2)
        date = datetime.datetime.strptime(datestr, '%a %b %d %H:%M:%S %Y')
        # print "DATE: " + str(date) + ", FROM: " + datestr
        return date

    def __grab_patch__(self):
        """
            Extract a patch from the file descriptor and the
            patch is returned as a list of lines.
        """

        patch = []
        line = self.buffer or self.fd.readline()

        while line:
            m = patterns['commit'].match(line)
            if m:
                patch = [line]
                break
            line = self.fd.readline()

        if not line:
            return None

        line = self.fd.readline()
        while line:
            # If this line starts a new commit, drop out.
            m = patterns['commit'].match(line)
            if m:
                self.buffer = line
                break
            m = patterns['date'].match(line)
            if m:
                date = self.getDate(line)
                if date < self.date_from or date > self.date_to:
                    # print "Date " + str(date) + ", not in [" + str(self.date_from) + " - " + str(self.date_to) + "]"
                    return "skip"

            patch.append(line)
            self.buffer = None
            line = self.fd.readline()

        return patch


if __name__ == '__main__':
    patches = LogPatchSplitter(sys.stdin, datetime.datetime(1970,1,1), datetime.datetime(2069,1,1))

    for patch in patches:
        print '---------- NEW PATCH ----------'
        for line in patch:
            print line,
