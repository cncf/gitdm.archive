#!/bin/bash
# USE_DB - use MySQL/MariaDB instead of PCRE library
# MANUAL - run mapping manually
# FULL - do not use cache
# CONFIG_FILE=file.txt
# SH_LOCAL_JSON_PATH=in.json
if [ ! -z "${USE_DB}" ]
then
  if ( [ -z "${SH_DSN}" ] && [ ! -z "$1" ] )
  then
    export SH_DSN="`cat SH_DSN.${1}.secret`"
  fi
  if [ -z "${SH_DSN}" ]
  then
    mysql -e "create user 'u' identified by 'p'"
    export SH_DSN='u:p@tcp(127.0.0.1:3306)/?charset=utf8'
  fi
fi
if [ ! -z "$MANUAL" ]
then
  ./map_orgs
else
  if [ -z "$FULL" ]
  then
    CACHED=1 TRUNC='' NO_ACQS=1 ./map_orgs && mv config.txt cncf-config/email-map && mv mapped.json github_users.json
  else
    CACHED='' TRUNC='' NO_ACQS=1 ./map_orgs && mv config.txt cncf-config/email-map && mv mapped.json github_users.json
  fi
fi
