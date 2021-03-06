# A Slackware Build Tool (asbt)

asbt is a tool for managing packages in your local copy of slackbuilds,
which can be obtained from http://slackbuilds.org/ (SBo), 
for Slackware Linux.

It supports following functions/options:

1.  search the repository (-s)
2.  info about specified package (-i)
3.  readme about specified package (-r)
4.  goto the package directory (-g)
5.  view slackbuild (-v)
6.  list files contained in specified package directory (-l,-L)
7.  description about specified package (-d)
8.  get / download the package (-G)
9.  build the package (-B)
10. install the built package (-I)
11. details about installed package (-D)
12. upgrade installed package with built package (-U)
13. remove installed package (-R)
14. query installed packages (-q)
15. view all packages installed from SBo (-q --sbo)
16. update the local git repo of slackbuilds (-u)
17. check for updates to installed packages (-c)
18. view the ChangeLog.txt from the local copy of the slackbuilds repo (-C)
19. track the source and built package for specified package (-t) 
20. enlist all packages which have given keyword in their .info file (-e)
21. enlist installed SBo packages which depend on given package (-e --rev)
22. tidy the source and package directories by removing old entries (-T)
23. process packages (-P), equivalent to get + build + install/upgrade
24. check and process updates to packages (-P --upgrade)

It uses the following Slackware tools:

1. installpkg
2. upgradepkg
3. removepkg

# Ideology

asbt runs as a normal application, and aids in package management of SBo packages by
displaying information about the packages, getting and building them,
checking updates to the packages, and viewing details about the installed packages, etc.

When root access is required, for example, when installing or removing packages,
sudo is used to gain the root privelege (if one is already root this does not matter).

This ensures demarcation between informational activites like searching or viewing information, and activites which change the system state, like installing or removing packages.

The variables used are:

~~~
1) REPODIR=""
 # Repository for slackbuilds.

2) SRCDIR=""
 # Where the downloaded source packages are to be placed.
 # Leave it blank for saving it in the same directory as the slackbuild.

3) PKGDIR=""
 # Where the build package will be placed. 
 # Leave it blank to use the slackbuild default (generally /tmp).

4) GITDIR=""
 # Directory where the slackbuilds git repository is present.

5) EDITOR=""
 # Editor for viewing/editing slackbuilds.

6) BUILDFLAGS=""
 # Common build flags specified while building packages.

7) IGNORE=""
 # Packages to ignore when checking for updates.

8) PAUSE="yes"
 # Pause for input when using superuser priviliges.

~~~

Samples for these variables are present in the script itself.

These can be overrided by specifying the options provided in the configuration file `/etc/asbt/asbt.conf`

# Installation

Via SBo,
http://slackbuilds.org/repository/14.2/system/asbt/

Or, (as root)
`make install`

# Post Installation

asbt can be setup using the command:

`asbt -S`

This checks if the slackbuilds repository is present, and is not empty.
If it is empty, it prompts to set it up by cloning the slackbuilds.org git repository.

Further it asks to set the variables in the configuration file `/etc/asbt/asbt.conf` (or `$HOME/.config/asbt.conf` if present).

# Usage

`asbt [option] [package]`

# Examples

~~~
asbt -s dosbox  # search for package dosbox
asbt -i dosbox  # read the info file for dosbox
asbt -v dosbox  # view / edit slackbuild
asbt -G dosbox  # get (download) dosbox (source)
asbt -B dosbox  # build package for dosbox
asbt -I dosbox  # install built package
asbt -D dosbox  # view details about installed package dosbox
asbt -q dosbox  # query whether dosbox is installed
asbt -q --sbo  # query all SBo intalled packages
asbt -q --all  # query all installed packages
asbt -c  # check for updates to packages installed from the repo
asbt -c all  # check all installed packages for updates to packages from repo
asbt -P --upgrade  # check for and upgrade out of date packages
asbt -e --rev gtkmm  # list installed SBo packages which depend on gtkmm
~~~

# Notes

* When searching, a `*`(wildcard) at both ends is implied.

  For example, if one wants to search for all packages which have the word "xfce", one can use `asbt search xfce`
instead of `asbt search '*xfce*'`

  A wildcard at both ends is also implied when querying.

* Giving package path instead of package name is also supported for some options. For example,

  `asbt -B ~/builds/thermal_daemon/thermal_daemon-1.1`

  Here the above path is the folder which contains the source and slackbuild and related files.

* While building packages, options can also be passed. For example,

  `asbt -B volumeicon NOTIFY=yes`

  These build options are different for every package, and can be found out by reading the package's README or Slackbuild.

* Build flags in the config file are passed to each package while building. 

  The default flags that are specified are: `MAKEFLAGS=-j2` (means use 2 CPU cores while building).

  However, some packages can fail to build on multiple cores (for example, webkitgtk).

  For such packages, while building, the buildargs can be overrided. For example,

  `asbt -B webkitgtk MAKEFLAGS=-j1`

* asbt copies the original slackbuild with a .asbt extension and modifies it before building.
  The CWD=$(pwd) line is changed to CWD=${CWD:-$(pwd)} so that it can build from any location by specifying the build location.
  The edited copy is deleted after building the package.

  But if for some reason the build process was interrupted/failed, the edited copy will need to be manually removed.

* To preserve any user changes to the slackbuilds repo, first the current git state is stashed with git stash save, and subsequently the repo is updated.
  To know more about git stash, try the git-stash man page.

* Using the -T (tidy) option, one can clean one's src or pkg directories of old items. It retains the latest 3 entries by date.

  The --dry-run option can be used to see which entries are going to be deleted. For example,

  `asbt -T --dry-run pkg`

* Since version 0.9.5, multiple packages can be specified for some options, like get (-G), install (-I), upgrade (-U), remove (-R), and process (-P). For example,

  `asbt -P i3 i3status`

  The packages are processed in the order they are specified.

  However, multiple packages cannot be specified for the build (-B) option, since the build option takes the extra arguments as build arguments for that package.

* From version 1.0, to update all SBo packages, the following command can be used:

  `asbt -P -u`

  While upgrading a package, reading its README is recommended though as its dependencies could have changed.

* From version 1.4, pauses for input when using superuser privileges.

  To override this behaviour `PAUSE=no` can be used in the config.

  With some options like `-G`, `-B`, `-I`, `-U`, `-R`, and `-P`, `-n` can be specified at the command line to disable pausing for input. For example,

  `asbt -P screenfetch dosbox -n`

* In version 1.7, some variables were capitalized to make it clear which ones are global in the code; users would need to adapt their config files to the changes.

* [hoorex](https://slackbuilds.org/repository/14.2/misc/hoorex/) is a tool to get information about the dependencies of a package in the repository, and can be used alongside asbt. For example,

  `asbt -P $(hoorex -r mousepad)`
