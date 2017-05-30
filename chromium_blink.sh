#./repo_in_range_with_exclude.sh ~/dev/src/ chromium 2016-05-01 2017-05-01 '^blink/'
#./repo_in_range_with_exclude.sh ~/dev/src/ chromium 2017-04-01 2017-05-01 '^blink/|/blink/'
#./repo_in_range_with_exclude.sh ~/dev/src/blink/ blink 2007-04-01 2017-05-01 '^blink/|/blink/'
./repo_in_range_with_exclude.sh ~/dev/src/ chromium 2016-05-01 2017-05-01 'blink'
