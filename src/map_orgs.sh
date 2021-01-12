#!/bin/bash
if ( [ -z "${SH_DSN}" ] && [ ! -z "$1" ] )
then
  export SH_DSN="`cat SH_DSN.${1}.secret`"
fi
./map_orgs
