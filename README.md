# app_rpt
**Refactoring and upgrade of AllStarLink's app_rpt, etc.**

# Debugging and Submitting Bugs

Feel free to open an issue for *any* trouble you might be experiencing with these modules. Please try to adhere to the following when submitting bugs:

- Enable debug to reproduce the issue. You can do this by running `core set debug 5 app_rpt` (less than or greater than 5 depending on the issue and how chatty the debug log level is). You can also enable debug all the time in `asterisk.conf`. To get debug output on the CLI, you will need to add the `debug` level to the `console => ` log file in `logger.conf`. A debug log from the CLI in the seconds leading immediately up to the issue should be provided.

- For segfault issues, a backtrace is needed. Use `ast_coredumper` to get a backtrace and post the relevant threads from `full.txt` (almost always Thread 1): https://wiki.asterisk.org/wiki/display/AST/Getting+a+Backtrace (you can also run `phreaknet backtrace` - make sure to adjust the paste duration from 24 hours if you link the paste link)

- Describe what led up to the issue and how it can be reproduced on our end.

- Any other context that might be helpful in fixing the issue.

Thank you!

# Development

## Prettifying

Note: This is an optional step. If you are touching existing code in a few places, then it is best to skip prettifying and just let the commit checker check for conformance to the coding standards. 

After installing clang-format and codespell, set up the pre-commit workflow.

From the top level project directory, execute:

`cp ./.dev/pre-commit ./.git/hooks/pre-commit`

This will enable coding standards to be checked locally.

## Recommended Pull Request (PR) Process

If you would like to add a new feature, bug fix, or documentation to ASL & App_rpt the following steps should give a general overview of the process. This is only a general guideline and specific steps could vary based on your preferences, tools, etc. Before starting on any new feature or fix it is recommended to open an Issue (or comment on an existing Issue) for a bug or enhancement request and give the ASL dev team a chance to review what you propose to do and provide feedback.

1. Set up ASL3 on a node using the steps in the [ASL Manual](https://allstarlink.github.io/install/), update all packages, install git
2. Make (or sync if already exists) a fork on github of https://github.com/AllStarLink/app_rpt
3. `cd ~; git clone git@github.com:AllStarLink/asl3-asterisk.git`
4. Download/copy DEBUG_ASTERISK.sh into ~
5. git clone your fork of app_rpt into ~ (if you had not already done so in the past), then `cd app_rpt`
	* Create and switch to a new branch in your fork for this PR, eg. `git checkout -b coolnewfeature`
	* Enable the ASL lint tools: `apt install clang-format codespell; cp .dev/pre-commit .git/hooks/pre-commit`. Changes you make will then be automatically reformatted if needed during commits to meet the Asterisk code formatting guidelines.
6. `cd ~/asl3-asterisk`
7. `./build-asl3 -l source build`
8. `cd ~/asl3-asterisk-*    # the merge directory`
9. `~/DEBUG_ASTERISK.sh save   # only needed once`
	* It is recommended to execute "~/DEBUG_ASTERISK.sh restore" before "apt upgrade".
10. `~/DEBUG_ASTERISK.sh install`
11. As changes are made during development run the following commands to rebuild
	* `cd ~/app_rpt`
	* `make`
	* `~/DEBUG_ASTERISK.sh install`
12. As changes have been tested and completed:
	* `cd ~/app-rpt`
	* `git commit -a -m "...describe changes made..."` See https://docs.asterisk.org/Development/Policies-and-Procedures/Commit-Messages/ for recommended format of commit messages. If PR fixes a bug add `Fixes #<bug#>` in the commit message
	* `git push    # Push changes to your fork`
	* Above commands may vary depending on if you are committing only certain changes, or amending a commit.
13. To restore saved ASL files after development is completed: `~/DEBUG_ASTERISK.sh restore`
14. If changes are made to the main ASL app_rpt repo while you have any PRs in development or not yet merged, it is generally recommended to only sync your fork on GitHub if changes in the main ASL repo would affect or conflict with your changes. In that case you can sync main/master on github, `git pull` the changes to your local repo main branch on the node and then rebase any branches with `git checkout <branch-name>; git rebase main; git push origin <branch-name>`.
15. Initiate Pull Request at https://github.com/AllStarLink/app_rpt/pulls
16. As feedback is received and other changes may be needed, repeat steps in (12.) and reply in PR comments with any useful details on changes that were made.

### Potentially useful git commands:
* List branches: `git branch`
* Switch to another branch: `git checkout <branch-name>`
* Check status, see local changes: `git status`, `git diff`

Use extreme care and confirm things with your research before using any of the below commands.
* If you did a local commit but need to undo it: `git reset HEAD^`
* If you pushed a commit but need to remove it: `git reset --hard <sha of commit to go back to>; git push --force`
* To reset a local branch that was corrupted eg. files accidentally deleted: `git reset --hard origin/<branch-name>` (**will overwrite all local changes**)


# Installing

You can use PhreakScript to install Asterisk automatically, first, then use the `rpt_install.sh` script to properly install the files from this repo.

## Automatic Installation

Updated instructions are in the ASL3-Manual repo at https://github.com/AllStarLink/ASL3-Manual/blob/main/docs/user-guide/install.md

Step 1: Install DAHDI and Asterisk

**For users:**

```
cd /usr/src && wget https://docs.phreaknet.org/script/phreaknet.sh && chmod +x phreaknet.sh && ./phreaknet.sh make
phreaknet install --alsa -d -b -v 20 # -d for DAHDI, add -s for chan_sip (if you need it still)
```

The critical flags here are `--alsa`, which adds ALSA support to the build system (required for `chan_simpleusb` and `chan_usbradio` to build) and `-d`, to install DAHDI.

**For developers:**

Developers should build Asterisk with DEVMODE enabled (for backtraces and assertions) and also install the test suite:

```
cd /usr/src && wget https://docs.phreaknet.org/script/phreaknet.sh && chmod +x phreaknet.sh && ./phreaknet.sh make
phreaknet install --alsa --dahdi --devmode --testsuite
```

Step 2: Install app_rpt modules

- Clone this repo into `/usr/src` on your system: `cd /usr/src; git clone https://github.com/AllStarLink/app_rpt.git`

- If you would like to also install the test suite, also clone the test suite now: `cd /usr/src; git clone https://github.com/asterisk/testsuite.git`

- Finally, run: `./rpt_install.sh`. This compiles Asterisk with the radio modules and adds the radio tests to the test suite, if it was present.

### Running the tests

If you installed the test suite, you can run the `app_rpt` tests by running `cd /usr/src/testsuite; ./runInVenv.sh python3 runtests.py --test=tests/apps/rpt`

You can also use the `phreaknet runtest` command during development (e.g. `phreaknet runtest apps/rpt`), as it has some helpful tooling and wrappers to help with debugging when tests fails.

## Manual Installation (not recommended)

If you want to manually install app_rpt et al., here is how:

### Pre-Reqs

`chan_simpleusb` and `chan_usbradio` require `libusb-dev` on Debian:

`apt-get install -y libusb-dev`

### Compiling

First, detection of the ALSA library needs to be re-added to the build system, by applying the following patch: https://github.com/InterLinked1/phreakscript/blob/master/patches/alsa.diff

Then, add this near the bottom of `apps/Makefile`:

`$(call MOD_ADD_C,app_rpt,$(wildcard app_rpt/rpt_*.c))`

Add this near the bottom of `channels/Makefile`:

`chan_simpleusb.so: LIBS+=-lusb -lasound`

`chan_usbradio.so: LIBS+=-lusb -lasound`

### After DAHDI/Asterisk installed

`/dev/dsp1` needs to exist for chan_simpleusb and chan_usbradio to work.

This StackOverflow post contains the answer in an upvoted comment: https://unix.stackexchange.com/questions/103746/why-wont-linux-let-me-play-with-dev-dsp/103755#103755

Run: `modprobe snd-pcm-oss` (as root/sudo)
