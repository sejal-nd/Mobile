This script will automatically generate a CSV file listing work items
currently in stage, and not yet on production, for EUCOMS.

## Setup

First, clone this repo to your local box.

Login to VSTS and create a Personal Access Token:

* [https://exelontfs.visualstudio.com/_usersSettings/tokens](https://exelontfs.visualstudio.com/_usersSettings/tokens)
* click "New Token"
* Make a text file in this repo, `token.txt` or use the `--token` parameter below (same content)
* In `token.txt`, write out your username and token as `{username}:{token}`
* for example, if my token was just "CDCDCDCD", I would write:
    * `e123057@exelonds.com:CDCDCDCD`

* Run the script! It will default to comparing EUCOMS master to stage, but there are parameters available:

	--target-project       Target project in VSTS (Example, EUCOMS or EU-Mobile)
	--target-repo          Target repo in VSTS (Example, EUCOMS, or Exelon_Mobile_iOS)
	--target-repo-path     Target path locally for the repo. If the repo already exists in this path, the script
	                       will just use that, if not, the script will clone the repo to that path
	--target-branch        Branch for the comparison. You probably want the higher of the two branches here, ex: master
	--source-branch        Branch to compare against, ex: stage
	--token                Use in lieu of a token.txt
	--output               csv or txt -- txt mode writes a consolidated list of things to `release_notes.txt` 
	--pull-request-number  Takes in a single PR number to write notes off of -- useful when attaching to PR branch policies