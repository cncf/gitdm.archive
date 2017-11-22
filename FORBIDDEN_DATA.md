# How to remove affiliations data

If You do not want your personal data like names and/or emails to be listed You can do the following.

- Clone cncf/gitdm locally
- Run `./add_forbidden_data.rb 'youremail@domain.com'` or `./add_forbidden_data.rb 'Your Name' 'your@email.com' 'anything you want to remove from repo'`
- Program will generate SHA256 hashes of data provided from command line arguments and add them to `cncf-config/forbidden.csv` file.
- Create PR with updated `cncf-config/forbidden.csv` file. That way Your sensitive data won't be visible in a PR.
- We will run `./handle_forbidden_data.sh` on your PR that will generate report with files containing that information.
- We will remove requested informations and merge your PR.
