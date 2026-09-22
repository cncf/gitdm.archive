# Add a non-cncf project/org ( project must be opensource ) to generate affiliations for it.
1. Add the developers of your organization/project to be get affiliated in `./developers_affiliations.txt` in the proper format. `cd src/`. Now generate new email-map using `./import_affs.sh`, then: `mv email-map cncf-config/email-map`.
 For e.g.
     ```
    developer1: email1@xyz, email2@abc, ...
        company1
        company2 until YYYY-MM-DD
    developer2: email3@xyz, email4@pqr, ...
        company3
        company4 until YYYY-MM-DD
     ```
2. Clone all repositories of the project at `~/dev/project_name/`. For cloning either you can use `cncf/velocity` project and writing sql query in BigQuery folder or you can create a new shellscript file in `~/dev/cncf/gitdm/` location with name `clone_project_name.sh`. 
    And just copy paste this code in that file
    ```
    #!/bin/bash
    mkdir ~/dev/project_name/ 2>/dev/null
    cd ~/dev/project_name || exit 1
    git clone github_repo_clone_url_for_your_project1 || exit 1
    git clone github_repo_clone_url_for_your_project2 || exit 1
    ...
    echo "All project_name repos cloned" 
    ```
    Paste all repository's clone_url manually.
    Save file and run this script `chmod +x ./clone_project_name.sh`.
    and then run this script - `./clone_project_name.sh` . This will clone all repos at the place `~/dev/project_name/`.

    **Notes** : replace project_name with your github organization name.

3. To generate `git.log` file, use this command `./all_repos_log.sh ~/dev/project_name/*`. Make it `uniq`.

4. To run `cncf/gitdm` on a generated `git.log` file do: `~/dev/cncf/gitdm/cncfdm.py -i git.log -r "^vendor/|/vendor/|^Godeps/" -R -n -b ./src/ -t -z -d -D -U -u -o all.txt -x all.csv -a all_affs.csv > all.out`

5. To generate human readable text affiliation files: `SKIP_COMPANIES="(Unknown)" ./gen_aff_files.sh`

6. If updating via `ghusers.sh` or `ghusers_cached.sh` (step 6), please update `repos` array in `./ghusers.rb` with your org/project repos lists, then run `generate_actors.sh` too. But before it, make sure that you had set devstats and update `./generate_actors.sh` after first line with `sudo -u postgres psql -tA your_pg_database_name < ~/dev/go/src/devstats/util_sql/all_actors.sql > actors.txt`. now run `./generate_actors.sh`.

7. Consider `./ghusers_cached.sh` or `./ghusers.sh` (if you run this, then copy result json somewhere and get 0-committers from previous version to save GH API points). Sometimes you should just run `./ghusers.sh` without cache.

8. `ghusers_partially_cached.sh` will refetch repos metadata and commits and get users data from `github_users.json` so you can save a lot of API points.

9. To update (enchance) `github_users.json` with new affiliations `./enchance_json.sh`.

10. To merge multiple GitHub logins data (for example propagate known affiliation to unknown or not found on the same GitHub login) run: `./merge_github_logins.sh`.
11. Because this can find new affiliations you can now use `./import_from_github_users.sh` to import back from `github_users.json` and then restart from step 3.

12. Run `./correlation.sh` and examine its output `correlations.txt` to try to normalize company names and remove common suffixes like Ltd., Corp. and downcase/upcase differences.

13. Run `./lookup_json.sh` and examine its output JSONs - those GitHub profiles have some useful data directly available - this will save you some manual research work.

14. ALWAYS before any commit to GitHub run: `./handle_forbidden_data.sh` to remove any forbiden affiliations, please also see `FORBIDDEN_DATA.md`.

15. You can use `./clear_affiliations_in_json.sh` to clear all affiliations on a generated `github_users.json`.

16. You can create smaller final json for `cncf/devstats` using `./strip_json.sh github_users.json stripped.json; cp stripped.json ~/dev/go/src/devstats/github_users.json`.

