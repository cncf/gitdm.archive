# CNCF gitdm

This is the Cloud Native Computing Foundation's fork of Jon Corbet and Greg KH's [gitdm](https://lwn.net/Articles/290957/) tool for calculating contributions based on developers and their companies. Companies and developers can check if they are correctly attributed at the following links:

Company Developers list: [co1], [co2], [co3], [co4], [co5], [co6], [co7], [co8].

Developers affiliations list: [dev1], [dev2], [dev3], [dev4], [dev5].

New affiliations are imported into DevStats about 1-2 times/month.

# DevStats

This repository is used as a source of affiliations for all [DevStats projects](https://devstats.cncf.io). The final [affiliations JSON](https://github.com/cncf/devstats/blob/master/github_users.json) is periodically imported by the [DevStats project](https://github.com/cncf/devstats).

# Adding/Updating affiliation

If you find any errors or missing affiliations in those lists, please submit a pull request with edits to developers affiliations files: [dev1], [dev2], [dev3], [dev4], [dev5], ...

Please note that we need both *current* and *historical* email here as we are processing data from GitHub *Archives*, so old emails are there (even if they are no longer current).

Only the Developers affiliations list [dev1], [dev2], [dev3], [dev4], [dev5], ... should be edited manually.

Company Developers lists [co1], [co2], [co3], [co4], [co5], [co6], [co7], [co8] are computed derivatives of the first list.

Other files used for affiliations are the [email map file](https://github.com/cncf/gitdm/blob/master/src/cncf-config/email-map) and [github users](https://github.com/cncf/gitdm/blob/master/src/github_users.json) file.

Please note that `cncf/gitdm` affiliations are imported into DevStats (`cncf/devstats`) once per 4 weeks.

# Removing affiliations

If you **do not want** to have your email listed here please read [how to remove your email](https://github.com/cncf/gitdm/blob/master/FORBIDDEN_DATA.md).
 
# Testing changes
 
You can test any changes locally by cloning this repository and regenerating all data by running `./rerun_data.sh`.

Then generate config files by running: `./import_affs.sh`. 

If those two files are out of sync, the tool will notify you about this.

This tool will generate a new `email-map` file. 

Check if your changes processed properly and move the file to `cncf-config/email-map` (replace)

# Sync workflow

Please follow the instructions from [SYNC.md](https://github.com/cncf/gitdm/blob/master/SYNC.md).

# Running
Use `*.sh` scripts to run analytics (`all*.sh` for full analysis and `rels*.sh` for per release stats)

This program assumes that gitdm resides in: `~/dev/cncf/gitdm/` and that kubernetes is in `~/dev/go/src/k8s.io/kubernetes/`

Output files are placed in the `kubernetes` directory.

To regenerate all statistics just run: `./rerun_data.sh`

This is an iterative process:
Run any of the scripts. Review its output in the `kubernetes` directory. Iteratively adjust mappings to handle more authors.

You can also run via `./debug.sh` to halt in debugger and review the hacker's structure and those who were not found. See `cncfdm.py`:`DebugUnknowns`

Final report:

[Data](https://docs.google.com/spreadsheets/d/15otmXVx8Gd6JzfiGP_OSjP8M9zyLeLof5-IGQKEb0UQ/edit?usp=sharing)

[Report](https://docs.google.com/document/d/1RKtRamlu4D_OpTDFTKNpMsmV51obdZlPWbXVj-LrDuw/edit?usp=sharing)


# Contributing

Pull requests are welcome.

Our mapping is never complete, please see config files in [Config files](https://github.com/cncf/gitdm/tree/master/src/cncf-config).

File [email-map](https://github.com/cncf/gitdm/blob/master/src/cncf-config/email-map) is a direct email to the employer mapping.

There is also a long list of unknown emails. For that, scroll to the section called `Developers with unknown affiliation`:
in [all.txt](https://github.com/cncf/gitdm/blob/master/src/all.txt)

All of those were searched for in various sources but we were not able to find their affiliation.

# Detailed Description

Regenerating all data with `./rerun_data.sh` means:
- Data for `kubernetes/kubernetes` repository (all time) with 3 mappings of Unknown developers: no mapping (list them with their email & name), map them to their email domain (`user@gmail.com` --> `'Gmail *'`), map all of them to '(Unknown)'. This is done via running: (`./all.sh`, `./all_no_map.sh`, `./all_with_map.sh`). Output goes to `kubernetes/all_time/` directory
- Data for `kubernetes/kubernetes` repository divided into releases v1.0.0, v1.1.0, ..., v1.7.0 (with 3 types of mappings described above). This is done via (`./rels.sh`, `./rels_strict.sh`, `./rels_no_map.sh`). Output goes to `kubernetes/v1.X.0-v1.Y.0/` directory: X=0,1,2,3,4,5,6 Y=1,2,3,4,5,6,7)

After performing those two steps, `cncfdm.py` output needs to be analysed. It is done by calling: `./analysis_all.sh` (analyses all-time results) and then `./analysis_rels.sh` (for pre-release data)

Data for all 68 repos (currently) which makes the entire Kubernetes project with `./kubernetes_repos.sh` script.

Final files generated by first 2 calls (for single repo kubernetes/kubernetes) are in `kubernetes/all_time/*.txt` and `./kubernetes/v1.X.0-v1.Y.0/*.txt`

All scripts are configured to ignore commits related to files from `vendor` and `Godeps` directories. 
This is because external sources are placed here and many commits are just adding external libraries. Accounting for them would make the results less accurate

All of them use a `git log` call with specific args piped to `cncfdm.py` call with specific parameters. 

See `./run.sh` for an example. All other calls use the same commands `git log` and `cncfdm.py` with other parameters.

To get a list of parameters for `cncfdm.py`, see comments inside of the `cncfdm.py` file describing all possible options. 

For more details about how `cncfdm.py` tool works refer to its sources and other `*.py` files.

Those files are analysed by `./analysis_all.sh` and `./analysis_rels.sh`. 

The first one calls:
`ruby analysis.rb all kubernetes/all_time/first_run_patch.txt kubernetes/all_time/run_no_map_patch.txt kubernetes/all_time/run_with_map_patch.txt`

The second calls:
`ruby analysis.rb v1.0_v1.1 kubernetes/*/output_strict_patch.txt kubernetes/*/output_patch.txt kubernetes/*/output_no_map_patch.txt`

This ruby tool expects to get 3 files (one with no unknown developers mapping, 2nd with mapping to a domain name and 3rd with mapping to (Unknown).

The output of this analysis.rb tool goes to `project/<prefix>_<key>_<type>`.csv files.
<prefix>: can be `all` or `v1.X.0-v1.Y.0` - it means that the file is for all time data or for a specific release of `kubernetes/kubernetes`
<key>: can be changeset, employers, lines, signoffs - it means that the file contains data sorted by this <key> desc.
<type>: can be `sum`, `top`, `all`:

- `all` means that the file contains all data for given <prefix> sorted by <key> desc (header is: `idx,company,n,percent` which means n-th, company name, n developers, % all developers) `All known` is the sum of all detected developers
- `top` means that there will be top 10 data from `all` but also must contain data for: '(Unknown)', 'Gmail *', 'Qq *', 'Outlook *', 'Yahoo *', 'Hotmail *', '(Independent)', '(Not Found)'. The header is the same as in `all`.
- `sum` contains a summary value for all found developers. It has a different header: `N companies,sum,percent` number of developer's companies found, the sum of <key> for all found developers, % of the sum <key> as a part of the sum <key> for all developers.
- Special names: `All known` (sum all known developers), `(Independent)` (developers working on their own), `(Not Found)` (developers for whom  an employer was not found even though the search was done in multiple sources), `(Unknown)` (developers not mapped (yet?)), `Some name *` (sum of developers having emails on `Some name` domain).An asterisk `*` is added to indicate this.

This data is directly used for the "Who writes Kubernetes" report.

`./kubernetes_repos.sh` script is used to generate all-time data for all the  kubernetes repos.

To use it, you must have all of kubernetes repositories (68 from 3 different organizations) cloned in `~/dev/go/src/k8s/`.

Orgs are: kubernetes, kubernetes-incubator, kubernetes-client.

It generates statistics for each single repo via:
`./anyrepo.sh ~/dev/go/src/k8s.io/<repo-name> <repo-name>`

See details in `./kubernetes_repos.sh`.
<repo-name> is a directory where a given kubernetes repository is cloned.

To clone a repository, do:
`cd ~/dev/go/src/k8s/`
`git clone https://github.com/<one-of-3-kubernetes-orgs>/<kubernetes-repo-name>.git`.

one-of-3-kubernetes-orgs: kubernetes, kubernetes-incubator and kubernetes-client

kubernetes-repo-name: please look up all repo names in all kubernetes orgs on GitHub.

`./anyrepo.sh` just calls `cncfdm.py` with appropriate args (like exclude vendor dir numstat etc).

There is also `./anyreporange.sh` that allows querying a repo for a specific time range (`cncfdm.py` supports that as well).

Output of this goes to `repos/<repo-name>.<ext>`
<repo-name>: repository name `./anyrepo.sh` was called with.
<ext>: txt, csv, html, out: txt: main data file, csv: dumps list of employers in given repo, html: the same as txt but in HTML format, out: `cncfdm.py` verbose output messages (for debugging)

Finally, `./kubernetes_repos.sh` calls:
`./multirepo.sh` with all 68 repository directories listed.

It gathers `git log` on each of them and concatenates all those files and then run `cncfdm.py` on the concatenated result (see `./multirepo.sh`)

Results are saved to `repos/combined.<ext>` <ext> is the same as for `anyrepo.sh`.

The typical workflow is re-runing `./kubernetes_repos.sh` and examining `repos/combined.txt` for unknown developers.

Research on google, Clearbit, FullContact, github, LinkedIn, Facebook, any other source -> update `cncf-config/<filename>` and re-run `./kubernetes_repos.sh`
<filename>: usually in this order: email-map, domain-map, a in very rare cases: aliases, gitdm.config-cncf or group mappings in groups/

Also, when running data for a single `kubernetes/kubernetes` for example with `./all.sh` examining developers found in `./kubernetes/all_time/first_run_patch.txt`.

After all this data is generated, `./kubernetes_repos.sh` concatenates all single repo data into a single output file: `repos/merged.out` to allow browsing all the data in a single file.

It also generates developers and companies statistics via a `./topdevs.sh` call.

It calls a ruby tool on the combined output of all 68 kubernetes repos (saved as CSV) like so: `ruby topdevs.rb repos/combined.csv`

That tool generates files as follows:
- `companies_by_name.csv` - this is a list of companies found, sorted by their names (not case sensitive) to allow manual examination for duplicates that came about from different names such as "Google" vs "Googe Corporation" vs "Google Corp." or "google"
- `companies_by_count.csv` - list of companies found, sorted (desc) by the number of employers. This serves a similar purpose but from a different perspective.
- `unknown_devs.txt`, `unknown_devs.csv`, `unknown_emails.csv` - list of developers for whom there isn't a mapping. Used to prioritize searching for devs, and `unknown_emails.csv` is in the format fitting a clearbit batch.

There are clearbit tools in `clearbit_tools/` directory. 

Look for any files with `.rb` extension. 3 rounds of commercial Clearbit requests were performed. And they returned quite a lot of data. 

But those files are not checked in and are listed in `./.gitignore` because we have to pay for that data.

Those tools are used to enrich of `cncf-config/email-map` mapping.
`google_other.txt` - contains a list of Google developers with email on a domain different than `@google.com`.
`./changesets.csv`, `./added.csv`, `./removed.csv` files contain developers sorted by changesets, added lines, removed lines desc. 

A new set of tools to get Clearbit and FullContact data is located in `affiliation_finder/` directory. The two tools are described inthe 'Tools to help find unknown affiliations' section of this document.

This is used to generate Top N developers in given criteria.

`./new_devs.sh` (also used by `./rerun_data.sh`) is used to generate statistics about new developers between `kubernetes/kubernetes` releases.

It calls: `ruby new_devs.rb kubernetes/v1.X.0-v1.Y.0/output_strict_patch.csv` for all X and Y.
`new_devs.rb` simply generates information about developers who were new between each release and file `new_devs.csv`, which contains a list of companies who introduced most new developers overall (sorted by # of new developers desc).

That covers a typical usage and data for "Who writes Kubernetes report"

## Other tools

Other tools include:
- `see_parser.sh` - display data feed as used by `cncfdm.py` tool
- `range.sh` - generate stats for `Linux kernel` for given data range (1st and 2nd command line argument like 2016-01-01 2017-01-01), assumes Linux repo (`torvalds/linux`) is cloned in `~/dev/linux/`
- `range_<period>.sh` - used to generate monthly, quarterly, yearly stats using above `./range.sh`, for example `./range_monthly.sh`.

To work on Prometheus contributors before and after joining CNCF:

Prometheus joined CNCF on 2016-05-09.

You need to clone all Prometheus repos into `~/dev/prometheus` using `./clone_prometheus.sh`

Then you need to get several distinct Prometheus contributors before joining CNCF:
./prometheus_repos.sh 2015-05-09 2016-05-08 ~/dev/prometheus/

Result is:
```
Processed 2721 csets from 230 developers
252 employers found
A total of 1558445 lines added, 353900 removed (delta 1204545)
```

Now check the number of distinct contributors after 2016-05-09:
`./prometheus_repos.sh 2016-05-09 2017-06-01 ~/dev/prometheus/`
```
Processed 2817 csets from 346 developers
365 employers found
A total of 2696196 lines added, 771502 removed (delta 1924694)
```

We have a change from 230 to 365 which is a 59% increase.

# Report
Links to data and generated report are here: `./res/links.txt`

# CNCF Projects join statistics
- CNCF Projects join dates are: https://github.com/cncf/toc#projects
- To generate statistics for Prometheus 90 days before joining CNCF and 90 days after joining try this:
- Run `./clone_prometheus.sh`
- Run `./cncf_join_analysis.sh prometheus 2016-05-09 90 ~/dev/prometheus/`
- Results go to `prometheus_repos/result.txt`

- Create a directory where you want to put links to kubernetes repos, like this: `mkdir ~/dev/kubernetes_repos_links`
- Copy `kubernetes_repos.sh` to `link_kubernetes_repos.sh`: `cp kubernetes_repos.sh link_kubernetes_repos.sh`
- Open the copy and add 1st line: `cd ~/dev/kubernetes_repos_links`
- Replace lines like `./anyrepo.sh ~/dev/go/src/k8s.io/test-infra/ test-infra` with `ln -s ~/dev/go/src/k8s.io/test-infra/ test-infra`; run it; done. k8s repos links are now in `~/dev/kubernetes_repos_links`
- The command that takes on Kubernetes repos should be: `./cncf_join_analysis.sh kubernetes 2016-03-10 90 ~/dev/kubernetes_repos_links`
- Results go to `kubernetes_repos/result.txt`

- To generate statistics for OpenTracing 90 days before joining CNCF and 90 days after joining try this:
- Run `./clone_opentracing.sh`
- Run `./cncf_join_analysis.sh opentracing 2016-08-17 90 ~/dev/opentracing/`
- Results go to `opentracing_repos/result.txt`

- There is also an All-in-one script to regenerate all CNCF Projects joint statistics, run `./join_stats.sh`

# Typical update of "Who writes Kubernetes report"
- Run `./pull_kubernetes.sh` to get all Kubernetes repos updated.
- Change directory to `dev/go/src/k8s.io/kubernetes/` and update this repository as well.
- New release since the last run (1.7) so many scripts needs to be updated. Also, all repos from 3 Kubernetes orgs are now in  ~/dev/kubernetes/repos so `./kubernetes_repos.sh` script needs an update as well
- Updated `kubernetes_repos.sh` script to get repos from `~/dev/kubernetes_repos/`
- Script to regenerate all data is `./rerun_data.sh`, it needs to be updated to support v1.7.0
- Now report is: https://docs.google.com/document/d/1RKtRamlu4D_OpTDFTKNpMsmV51obdZlPWbXVj-LrDuw/edit?usp=sharing
- Report data sheet/draft is: https://docs.google.com/spreadsheets/d/15otmXVx8Gd6JzfiGP_OSjP8M9zyLeLof5-IGQKEb0UQ/edit#gid=0
- Now report sections:
```
Since the Kubernetes project started in June 2014, 2623 Developers from 789 Companies worked on it (counting Kubernetes and all its projects 68 repos from 3 orgs).
A total of 28.4 million lines of code were added, 16.3 million lines removed.
```
Taken from: `./repos/combined.txt`
```
Processed 59041 csets from 2623 developers
789 employers found
A total of 28440262 lines added, 16342872 removed (delta 12097390)
```
For a single kubernetes/kubernetes repo, the data is in: `kubernetes/all_time/first_run_numstat.txt`
```
Processed 28225 csets from 1338 developers
400 employers found
A total of 6667288 lines added, 4132224 removed (delta 2535064)
```
- About how to fill data sheet/chart:
- Sheet "all time data":
- `analysis_all_repos.sh`, generates files starting with: `report/all_repos_rest`
- `report/prefix_key_type` (prefix: all - for kubernetes/kubernetes, all_repos - for all repos, v1.x for releases), project/<prefix>_<key>_<type>
- Commits info is in `other_repos/all_kubernetes_dtfrom_dtto` and `other_repos/kubernetes_dtfrom_dtto` (for all k8s repos and kubernetes/kubernetes alone)
- To see commits for all kubernetes repos combined for last year & for last 12 months (each) separately: `grep -HIn "csets from" other_repos/all_kubernetes_range_unknown_201*`
- The same for `kubernetes/kubernetes` repo: `grep -HIn "csets from" other_repos/kubernetes_range_unknown_201*`
- Update report and report data sheet with those results
- Number of github events etc - from `cncf/velocity:projects/unlimited.csv` (this is for 201606-201705)
- Values for May 2017 are in: `cncf/velocity:projects/cncf_projects_201705.csv`
```
activity,comments,prs,commits,issues,authors
Last year: 308313,217684,46351,16000,28278,1728
Last month: 30227,21371,4645,1741,2470,451
```
- Analyses of kubernetes/kubernetes (main repo) are in this format: `report/all_{key}_top.csv`, import them to the 2nd sheet
- Big summaries like all developers etc are in `./repos/combined.txt`, for the main k8s repo: `kubernetes/all_time/first_run_numstat.txt`
- Top developer stats are here: `stats/all_key.csv` (for all repos), `stats/kubernetes_key.csv` (for the main repo) and `stats/v1.x_key.csv` per versions.
- Import those to the last 3 sheets in the data set
- Per verion data: `report/v1.x_v1.y_key_top.csv`, key: changesets, lines, developers, import to the datasheet for all versions: 7 x 3 = 21 imports

Affiliations of some developers are uncertain despite the best effort. These developers are listed in `uncertain.csv` file.

## GitHub users can be pulled using Octokit GitHub API.

To do this, call: `ruby ghusers.rb` or `./ghusers.sh`

Required are:
- Standard GitHub OAuth token: https://github.com/settings/tokens --> Personal access tokens, put it in `/etc/github/oauth` file.
- A GitHub Application to increase the rate limit from 60 to 5000 (60 is not enough to process kubernetes, 5000 is enough).
- See: https://github.com/settings/ --> OAuth application, put your client_id and client_secret in `/ect/github/client_id`, `/etc/github/client_secret` files.
- This tool will cache all GitHub calls (save them as JSON files in `./ghusers/`) 
- Final JSON will be saved in `./github_users.json` (subsequent calls will use data from this file, so to reset cache, just remove this file and all files from `ghusers/` directory
- To generate the actual mapping, manually process this JSON (and do some mapping of company names - GitHub users sometimes put strange values there)
- I've done that by iteratively using a new tool: `import_from_github_users.sh`, `import_from_github_users.rb` with a mapping file (that tries to map a GitHub  user company name into something more accurate): `company-names-mapping`

## Tools to help find unknown affiliations
To enhance this json with pre-existing affiliations, call: `./enchance_json.sh`

- To generate JSON with some filtered data (like all unknown devs with location or LinkedIn profile link or just a blog entry) call: `./lookup_json.sh` (see the script for details, also lookup_json.rb have a lot of comments on how to use it).

- To generate a progress report (report about how many Not Found, Unknowns, and Independent devs are defined in our affiliation, call: `./progress_report.sh`).

- To generate aliases for emails that are already known (are using the same GitHub user name) try `./aliaser.sh`, the output is `aliaser.txt` that can be analyzed and manually added to `cncf-config/aliases` if needed.

- To generate a correlations map for company name (to avoid mapping typos etc) run `./correlations.sh` script.The result is in `correlations.txt` file that can be used to update `cncf-config/email-map` with corrected employer names.

- To generate per-files/directories statistics, use: `./per_dirs.sh`, this is a part of a standard workflow, results are in csv files in the `per_dirs` directory

- To generate affiliation files (`developers_affiliations.txt`, `company_developers.txt`), use `./gen_aff_files.sh`

- To generate data for the stacked chart, run `./stacked_chart_<months|rels>_<csets|perc>.sh`. It generates a csv file: `stacked_chart_<months|rels>_<csets|perc>.csv`, to generate all stacked charts: `./stacked_charts.sh`

- To import data from pretty-formatted files use `import_affs.sh`, this is not a part of the standard workflow

All those tools are automatically called when running the full data regeneration script: `./rerun_data.sh`

- To automatically find affiliations (email to the company) using Clearbit, run two scripts from the affiliation_finder folder in order:
	- `clearbit_affiliation_lookup.rb`
	- `ruby clearbit_affiliation_merge.rb`

The first one works with one argument and generates a file `clearbit_affiliation_lookup.csv`. The argument can be skipped or have a value of 'true' or 'false' - default. Invocation would be `clearbit_affiliation_lookup.rb` or `clearbit_affiliation_lookup.rb false` or `clearbit_affiliation_lookup.rb true`. The argument is used to whether the script's output data should be overwritten (normally data would be appended to the file) and at the same time it will allow previously looked-up email addresses to be checked again.<br/>The execution environment needs to have a proper value for this: 
	```
	Clearbit.key = ENV['CLEARBIT_KEY']
	```
It is a secret API key on a Clearbit account that has been set up for a subscription. When the file is generated, open it in a csv editor, sort by the 'chance' field. Visually check and correct data in the 'affiliation_suggestion' column. Replace values such as 'http://www.ghostcloud.cn/' with 'Ghostcloud'. If you find affiliations for other developers manually, just change the 'none' value in the 'chance' column to 'high' and provide a value in the 'affiliation_suggestion' column. Columns to the right of 'affiliation_suggestion' are not required.

The second script reads the 'clearbit_affiliation_lookup.csv' file. Data is processed against the `cncf-config/email-map` file. When done, the 'email-map' file will have new and updated affiliations. The file will be sorted as well. The lookup file will not be altered.

- To automatically find affiliations (email to company) using FullContact, run two scripts from affiliation_finder folder in order:
	- `ruby fullcontact_affiliation_lookup.rb`
	- `ruby fullcontact_affiliation_merge.rb`

The first one works with one argument and generates a file `fullcontact_affiliation_lookup.csv`. The argument can be skipped or have a value of 'true' or 'false' - default. Invocation would be `fullcontact_affiliation_lookup.rb` or `fullcontact_affiliation_lookup.rb false` or `fullcontact_affiliation_lookup.rb true`. The argument is used to whether the script's output data should be overwritten (normally data would be appended to the file) and at the same time it will allow previously looked-up email addresses to be checked again.<br/>The execution environment needs to have a proper value for this: 
	```
	config.api_key = ENV['FULLCONTACT_KEY']
	```
It is a secret API key on a FullContact account that has been set up for a subscription. The columns differ in this file compared to that of Clearbit. If you find affiliations for other developers manually, just change the value in the 'org_1' column. The column by default should have 5 pipe-delimited values. If you do not have the values for the other 4, just type 4 pipes. Columns to the right of 'org_1' are not required.

The second script reads the 'clearbit_affiliation_lookup.csv' file. Data is processed against the `cncf-config/email-map` file. When done, the 'email-map' file will have new and updated affiliations. The file will be sorted as well. The lookup file will not be altered. The merge scripts export developer work history to `fullcontact_developer_historical_irganizations.csv`.

# Add a new project ( cncf or non-cncf) to get affiliation for it.

Please follow the instructions from [ADD_PROJECT.md](https://github.com/cncf/gitdm/blob/master/ADD_PROJECT.md).

# Authors
- Łukasz Gryglicki <lgryglicki@cncf.io> - developement.
- Justyna Gryglicka <jgryglicka@cncf.io> - researching affiliations data.

<!-- Links -->

[dev1]: https://github.com/cncf/gitdm/blob/master/developers_affiliations1.txt
[dev2]: https://github.com/cncf/gitdm/blob/master/developers_affiliations2.txt
[dev3]: https://github.com/cncf/gitdm/blob/master/developers_affiliations3.txt
[dev4]: https://github.com/cncf/gitdm/blob/master/developers_affiliations4.txt
[dev5]: https://github.com/cncf/gitdm/blob/master/developers_affiliations5.txt
[co1]: https://github.com/cncf/gitdm/blob/master/company_developers1.txt
[co2]: https://github.com/cncf/gitdm/blob/master/company_developers2.txt 
[co3]: https://github.com/cncf/gitdm/blob/master/company_developers3.txt 
[co4]: https://github.com/cncf/gitdm/blob/master/company_developers4.txt
[co5]: https://github.com/cncf/gitdm/blob/master/company_developers5.txt
[co6]: https://github.com/cncf/gitdm/blob/master/company_developers6.txt
[co7]: https://github.com/cncf/gitdm/blob/master/company_developers7.txt
[co8]: https://github.com/cncf/gitdm/blob/master/company_developers8.txt
