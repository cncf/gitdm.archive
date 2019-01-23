#!/bin/sh
find . -type f ! -wholename "*.git/*" -exec grep -HIn "$*" "{}" \;
