#!/bin/bash

# provide debugging output when desired
function DEBUG {
    [ "$GITDM_DEBUG" == "on" ] && echo "DEBUG: $1"
}

# enable/disable debugging output
GITDM_DEBUG=${GITDM_DEBUG:-"off"}

# determine if a given parameter is a date matching the format YYYY-MM-DD,
# i.e. 2013-09-13   This is used to decide if git should specify a start
# date with '--since YYYY-MM-DD' rather than use an absolute changeset id
function IS_DATE {
    [[ $1 =~ ^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$ ]]
}

GITBASE=${GITBASE:-~/git/openstack}
RELEASE=${RELEASE:-havana}
BASEDIR=$(pwd)
CONFIGDIR=$(pwd)/openstack-config
TEMPDIR=${TEMPDIR:-$(mktemp -d $(pwd)/dmtmp-XXXXXX)}
GITLOGARGS="--no-merges --numstat -M --find-copies-harder"
REPOBASE=${REPOBASE:-http://review.openstack.org/p/openstack}

UPDATE_GIT=${UPDATE_GIT:-y}
GIT_STATS=${GIT_STATS:-y}
# LP_STATS disabled by default, they take forever
LP_STATS=${LP_STATS:-n}
QUERY_LP=${QUERY_LP:-y}
GERRIT_STATS=${GERRIT_STATS:-y}
REMOVE_TEMPDIR=${REMOVE_TEMPDIR:-y}
TIMESTAMP=`date`
# brief header to prepend to all of the analysis results
OUTPUT_HEADER="Statistics generated at ${TIMESTAMP}"

if [ ! -d .venv ]; then
    echo "Creating a virtualenv"
    ./tools/install_venv.sh
fi

if [ "$UPDATE_GIT" = "y" ]; then
    echo "Updating projects from git"
    if [ ! -d ${GITBASE} ] ; then
        DEBUG "Creating missing ${GITBASE}"
        mkdir -p ${GITBASE}
    fi
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project x; do
            if [ ! -d ${GITBASE}/${project} ] ; then
                DEBUG "Cloning missing ${project} from ${REPOBASE}/${project}"
                git clone ${REPOBASE}/${project} ${GITBASE}/${project}
            fi
            cd ${GITBASE}/${project}
            DEBUG "Fetching updates to ${project}"
            git fetch origin 2>/dev/null
        done
fi

if [ "$GIT_STATS" = "y" ] ; then
    echo "Generating git commit logs"
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project revisions excludes x; do
            DEBUG "Generating git commit log for ${project}"
            cd ${GITBASE}/${project}
            # match possible dates of the format YYYY-MM-DD to use in
            # supplying git with a '--since DATE' paramter instead of a
            # range of changeset ids
            if IS_DATE $revisions; then
                DEBUG "Matched a git --since date of '${revisions}'"
                revisions="--since ${revisions}"
            fi
            git log ${GITLOGARGS} ${revisions} > "${TEMPDIR}/${project}-commits.log"
            if [ -n "$excludes" ]; then
                awk "/^commit /{ok=1} /^commit ${excludes}/{ok=0} {if(ok) {print}}" \
                    < "${TEMPDIR}/${project}-commits.log" > "${TEMPDIR}/${project}-commits.log.new"
                mv "${TEMPDIR}/${project}-commits.log.new" "${TEMPDIR}/${project}-commits.log"
            fi
        done

    echo "Generating git statistics"
    cd ${BASEDIR}
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project x; do
            DEBUG "Generating git stats for ${project}"
            echo "${OUTPUT_HEADER}" > "${TEMPDIR}/${project}-git-stats.txt"
            python gitdm -l 20 -n < "${TEMPDIR}/${project}-commits.log" >> "${TEMPDIR}/${project}-git-stats.txt"
            # also create a full dump with csv for further downstream processing
            echo "${OUTPUT_HEADER}" > "${TEMPDIR}/${project}-git-stats.csv"
            python gitdm -n -y -z -x "${TEMPDIR}/${project}-git-stats.csv" < "${TEMPDIR}/${project}-commits.log" >> "${TEMPDIR}/${project}-git-stats-all.txt"
        done

    DEBUG "Generating aggregate git stats for all projects"
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project x; do
            cat "${TEMPDIR}/${project}-commits.log" >> "${TEMPDIR}/git-commits.log"
        done
    echo "${OUTPUT_HEADER}" > "${TEMPDIR}/git-stats.txt"
    python gitdm  -n -y -z -x "${TEMPDIR}/git-stats.csv" < "${TEMPDIR}/git-commits.log" >> "${TEMPDIR}/git-stats.txt"
fi

if [ "$LP_STATS" = "y" ] ; then
    echo "Generating a list of bugs"
    cd ${BASEDIR}
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project x; do
            DEBUG "Generating a list of defects for ${project}"
            if [ ! -f "${TEMPDIR}/${project}-bugs.log" -a "$QUERY_LP" = "y" ]; then
                ./tools/with_venv.sh python launchpad/buglist.py ${project} ${RELEASE} > "${TEMPDIR}/${project}-bugs.log"
            fi
            while read id person date x; do
                emails=$(awk "/^$person / {print \$2}" ${CONFIGDIR}/launchpad-ids.txt)
                echo $id $person $date $emails
            done < "${TEMPDIR}/${project}-bugs.log" > "${TEMPDIR}/${project}-bugs.log.new"
            mv "${TEMPDIR}/${project}-bugs.log.new" "${TEMPDIR}/${project}-bugs.log"
        done

    echo "Generating launchpad statistics"
    cd ${BASEDIR}
    echo "${OUTPUT_HEADER}" > "${TEMPDIR}/${project}-lp-stats.txt"
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project x; do
            DEBUG "Generating launchpad stats for ${project}"
            grep -v '<unknown>' "${TEMPDIR}/${project}-bugs.log" |
                python lpdm -l 20 >> "${TEMPDIR}/${project}-lp-stats.txt"
        done

    DEBUG "Generating aggregate launchpad stats for all projects"
    > "${TEMPDIR}/lp-bugs.log"
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project x; do
            grep -v '<unknown>' "${TEMPDIR}/${project}-bugs.log" >> "${TEMPDIR}/lp-bugs.log"
        done
    echo "${OUTPUT_HEADER}" > "${TEMPDIR}/lp-stats.txt"
    grep -v '<unknown>' "${TEMPDIR}/lp-bugs.log" |
        python lpdm -l 20 >> "${TEMPDIR}/lp-stats.txt"
fi

if [ "$GERRIT_STATS" = "y" ] ; then
    echo "Generating a list of Change-Ids"
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project revisions x; do
            cd "${GITBASE}/${project}"
            # match possible dates of the format YYYY-MM-DD to use in
            # supplying git with a '--since DATE' paramter instead of a
            # range of changeset ids
            if IS_DATE $revisions; then
                DEBUG "Matched a git --since date of '${revisions}'"
                revisions="--since ${revisions}"
            fi
            git log ${revisions} |
                awk '/^    Change-Id: / { print $2 }' |
                split -l 100 -d - "${TEMPDIR}/${project}-${RELEASE}-change-ids-"
        done

    cd ${TEMPDIR}
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project x; do
            > ${project}-${RELEASE}-reviews.json
            for f in ${project}-${RELEASE}-change-ids-??; do
                echo "Querying gerrit: ${f}"
                ssh -p 29418 review.openstack.org \
                    gerrit query --all-approvals --format=json \
                    $(awk -v ORS=' OR '  '{print}' $f | sed 's/ OR $//') \
                    < /dev/null >> "${project}-${RELEASE}-reviews.json"
            done
        done

    echo "Generating a list of commit IDs"
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project revisions x; do
            DEBUG "Generating a list of commit IDs for ${project}"
            cd "${GITBASE}/${project}"
            # match possible dates of the format YYYY-MM-DD to use in
            # supplying git with a '--since DATE' paramter instead of a
            # range of changeset ids
            if IS_DATE $revisions; then
                DEBUG "Matched a git --since date of '${revisions}'"
                revisions="--since ${revisions}"
            fi
            git log --pretty=format:%H $revisions > \
                "${TEMPDIR}/${project}-${RELEASE}-commit-ids.txt"
        done

    echo "Parsing the gerrit queries"
    cd ${BASEDIR}
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project x; do
            DEBUG "Parsing the gerrit queries for ${project}"
            python gerrit/parse-reviews.py \
                "${TEMPDIR}/${project}-${RELEASE}-commit-ids.txt" \
                "${CONFIGDIR}/launchpad-ids.txt" \
                < "${TEMPDIR}/${project}-${RELEASE}-reviews.json"  \
                > "${TEMPDIR}/${project}-${RELEASE}-reviewers.txt"
        done

    echo "Generating gerrit statistics"
    cd ${BASEDIR}
    echo "${OUTPUT_HEADER}" > "${TEMPDIR}/${project}-gerrit-stats.txt"
    echo "${OUTPUT_HEADER}" > "${TEMPDIR}/${project}-gerrit-stats-all.txt"
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project x; do
            DEBUG "Generating gerrit statistics for ${project}"
            python gerritdm -l 20 \
                < "${TEMPDIR}/${project}-${RELEASE}-reviewers.txt" \
                >> "${TEMPDIR}/${project}-gerrit-stats.txt"
            python gerritdm -z \
                < "${TEMPDIR}/${project}-${RELEASE}-reviewers.txt" \
                >> "${TEMPDIR}/${project}-gerrit-stats-all.txt"
        done

    DEBUG "Generating aggregate gerrit statistics for all projects"
    > "${TEMPDIR}/gerrit-reviewers.txt"
    grep -v '^#' ${CONFIGDIR}/${RELEASE} |
        while read project x; do
            cat "${TEMPDIR}/${project}-${RELEASE}-reviewers.txt" >> "${TEMPDIR}/gerrit-reviewers.txt"
        done
    echo "${OUTPUT_HEADER}" > "${TEMPDIR}/gerrit-stats.txt"
    echo "${OUTPUT_HEADER}" > "${TEMPDIR}/gerrit-stats-all.txt"
    python gerritdm -l 20 < "${TEMPDIR}/gerrit-reviewers.txt" >> "${TEMPDIR}/gerrit-stats.txt"
    python gerritdm -z < "${TEMPDIR}/gerrit-reviewers.txt" >> "${TEMPDIR}/gerrit-stats-all.txt"
fi

DEBUG "Cleaning up"
cd ${BASEDIR}
rm -rf ${RELEASE} && mkdir ${RELEASE}
mv ${TEMPDIR}/*stats.txt ${RELEASE}
mv ${TEMPDIR}/*stats-all.txt ${RELEASE}
mv ${TEMPDIR}/*.csv ${RELEASE}

[ "$REMOVE_TEMPDIR" = "y" ] && rm -rf ${TEMPDIR} || echo "Not removing ${TEMPDIR}"
