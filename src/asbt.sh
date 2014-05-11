#!/bin/bash
# asbt : A tool to manage packages in a local slackbuilds repository.
##
# Copyright (C) 2014 Aaditya Bagga <aaditya_gnulinux@zoho.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed WITHOUT ANY WARRANTY;
# without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
##

ver="0.9.2 (dated: 11 May 2014)" # Version

# Variables used:

repodir="/home/$USER/slackbuilds" # Repository for slackbuilds. Required.
#repodir="/home/$USER/git/slackbuilds" # Alternate repository for slackbuilds.

srcdir="/home/$USER/src" # Where the downloaded source is to be placed.
#srcdir="" # Leave blank for saving it in the same directory as the slackbuild.

outdir="/home/$USER/packages" # Where the built package will be placed.
#outdir="" # Leave it blank for putting built package(s) in /tmp.

gitdir="/home/$USER/slackbuilds/.git" # Slackbuilds git repo directory.
#gitdir="" # Leave it blank if you dont want to use the --update option.

config="/etc/asbt/asbt.conf" # Config file which over-rides above defaults.
#config="" # Leave it blank for using above defaults

editor="/usr/bin/vim" # Editor for viewing/editing slackbuilds.
#editor="/usr/bin/nano" # Alternate editor

#--------------------------------------------------------------------------------------#

# Exit on error(s) - optional - as most errors are manually handled.
#set -e

package="$2" # Name of package input by the user.

# Check for the configuration file 
if [ -e "$config" ]; then
	. "$config"
fi

edit-config () {
	echo "Enter your password to view and edit the configuration file."
	if [ -e $editor ]; then
	       sudo -k $editor $config
	elif [ -e /usr/bin/nano ]; then
	       sudo -k nano $config
	elif [ -e /usr/bin/vim ]; then
		sudo -k vim $config
	else
	       echo "Unable to find editor to edit the configuration file $config"
	       exit 1
	fi
}

# Check the repo directory
check-repo () {
if [ ! -d "$repodir" ] || [ $(ls "$repodir" | wc -w) -le 0 ]; then
		echo "SlackBuild repository $repodir does not exist or is empty."
		echo -n "Would you like to setup? [y/N]: "
		read -e choice
		if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
			setup
		else
			exit 1
		fi
	fi
}

# Check the src and out directories
check-src-dir () {
	if [ ! -d "$srcdir" ]; then
		echo "Source directory $srcdir does not exist."
		exit 1
	fi
}

check-out-dir () {
	if [ ! -d "$outdir" ]; then
		echo "Output directory $outdir does not exist."
		exit 1
	fi
}

create-git-repo () {
	echo -n "Clone the Slackbuild repository from www.slackbuilds.org? [Y/n]: "
	read -e ch2
	if [ "$ch2" == "n" ] || [ "ch2" == "N" ]; then
		exit 1
	else
		# A workaround has to be applied to clone the git directory as the basename of the repodir
		cd "$repodir/.." && rmdir --ignore-fail-on-non-empty $(basename "$repodir") && git clone git://slackbuilds.org/slackbuilds $(basename "$repodir") | exit 1
	fi
}

# Setup function
setup () {
	if [ ! -d "$repodir" ]; then
		echo "Slackbuild repository not present."
	       	echo -n "Press y to set it up, or n to exit [Y/n]: "
		read -e ch
		if [ "$ch" == "n" ] || [ "$ch" == "N" ]; then
			exit 1
		else
			echo "Default Slackbuilds directory: /home/$USER/slackbuilds"
	       		echo -n "Press y use it, or n to change [Y/n]: "
			read -e ch1
			if [ "$ch1" == "n" ] || [ "$ch1" == "N" ]; then
				echo "Enter path of existing directory to use, or path of new dirctory to create: "
				read repopath
				if [ -d $repopath ]; then
					repodir="$repopath"
				else
					mkdir "$repopath" | exit 1
					repodir="$repopath"
				fi
			else
				if [ ! -d /home/$USER/slackbuilds ]; then
					mkdir /home/$USER/slackbuilds
				fi
			fi
		fi
		
		# Edit the config file to reflect above changes
		edit-config

		# Re-read the config file and check repo
		. $config
		check-repo
		
		# Now create git repo from upstream
		if [ $(ls "$repodir" | wc -w) -le 0 ]; then
			echo "Slackbuild repository seems to be empty."
			create-git-repo
		fi	

	elif [ $(ls "$repodir" | wc -w) -le 0 ]; then
		echo "Slackbuild repository seems to be empty."
		create-git-repo
	else
		edit-config
		. $config
		create-git-repo
	fi
}

# Check the no of input parameters
check-input () {
	if [ $# -gt 2 ] ; then
		echo "Invalid syntax. Type asbt -h for more info."
		exit 1
	fi
}

# Check number of arguments 
check-option () {
	if [ ! "$1" ]; then
		echo "Additional parameter required for this option. Type asbt -h for more info."
		exit 1
	fi
}

# Get the full path of a package
get-path() {
	# Check if path to package is specified instead of package name
	if [ -d "$package" ]; then
		path=$(readlink -f "$package")
		# Get the name of the package
		if [ -f "$path"/*.SlackBuild ]; then
			package=$(find "$path" -name "*.SlackBuild" -printf "%P\n" | cut -f 1 -d ".")
		else
			echo "asbt: Unable to process $package"
			exit 1
		fi
	else
		path=$(find -L "$repodir" -maxdepth 2 -type d -name "$package")
	fi
	# Check path (if directory exists)
	if [ ! -d "$path" ]; then
		echo "Directory: $repodir/$package N/A"
		exit 1
	fi
}

get-info () {
	# Source the .info file to get the package details
	if [ -f "$path/$package.info" ]; then
		. "$path/$package.info"
		echo "asbt: $path/$package.info sourced."
	else
		echo "asbt: $path/$package.info N/A"
		exit 1
	fi
}

get-content () {
	if [ -f "$1" ]; then
		# Return the content of the argument passed.
		cat "$1"
	else
		echo "File: $1 N/A"
		exit 1
	fi
}

# Get info about the source of the package
get-source-data () {
	get-info
	if [[ $(uname -m) == "x86_64" ]] && [[ -n "$DOWNLOAD_x86_64" ]] && [[ -n "$MD5SUM_x86_64" ]]; then
		link="$DOWNLOAD_x86_64"
		arch="x86_64"
	else
		link="$DOWNLOAD"
	fi
	src=$(basename "$link")
	# Check if src contains PRGNAM in the name
	if [ ! $(echo "$src" | grep "$PRGNAM") ]; then
		# Append PRGNAM to the beginning and check
		if [ -e "$path/$PRGNAM-$src" ]; then
			md5=$(md5sum "$path/$PRGNAM-$src" | cut -f 1 -d " ")
			pkgnam="$PRGNAM-$src"
			src="$pkgnam"
		elif [ -f "$srcdir/$PRGNAM-$src" ]; then
			md5=$(md5sum "$srcdir/$PRGNAM-$src" | cut -f 1 -d " ")
			pkgnam="$PRGNAM-$src"
			src="$pkgnam"
		# Check src without PRGNAM also
		elif [ -e "$path/$src" ]; then
			md5=$(md5sum "$path/$src" | cut -f 1 -d " ")
		elif [ -f "$srcdir/$src" ]; then
			md5=$(md5sum "$srcdir/$src" | cut -f 1 -d " ")
		fi
	else
		#src alrady contains PRGNAM in the name
		if [ -e "$path/$src" ]; then
			md5=$(md5sum "$path/$src" | cut -f 1 -d " ")
		elif [ -f "$srcdir/$src" ]; then
			md5=$(md5sum "$srcdir/$src" | cut -f 1 -d " ")
		fi
	fi
}

check-source () {
	get-source-data
	# Check if source has already been downloaded
	if [ -e "$path/$src" ]; then
		# Check validity of downloaded source
		if [ "$arch" == "x86_64" ]; then
			# 64 bit source
			if [ "$md5" == "$MD5SUM_x86_64" ]; then
				# Source valid
				valid=1
				echo "asbt: md5sum matched."
			else
				valid=0	
			fi
		else
			if [ "$md5" == "$MD5SUM" ]; then
				# Source valid
				valid=1
				echo "asbt: md5sum matched."
			else
				valid=0
			fi
		fi
	# Check if source present but not linked
	elif [ -f "$srcdir/$src" ]; then
		# Check validity of downloaded source
		if [ "$arch" == "x86_64" ]; then
			if [ "$md5" == "$MD5SUM_x86_64" ]; then
				ln -svf "$srcdir/$src" "$path" && valid=1
			else
				valid=0
			fi
		else
			if [ "$md5" == "$MD5SUM" ]; then
				ln -svf "$srcdir/$src" "$path" && valid=1
			else
				valid=0
			fi
		fi
	else
		valid=0
	fi
}

download-source () {
	echo "Downloading $src"
	# Check if srcdir is specified (if yes, download is saved there)
	if [ -z "$srcdir" ]; then
		wget --tries=5 --directory-prefix="$path" -N "$link" || exit 1
	else
		wget --tries=5 --directory-prefix="$srcdir" -N "$link" || exit 1
		# Check if downloaded package contains the package name or not
		if [ ! $(echo "$src" | grep "$PRGNAM") ] && [ $(echo "$src" | wc -c) -le 15 ]; then
			# Rename it and link it
			mv "$srcdir/$src" "$srcdir/$PRGNAM-$src"
			ln -sf "$srcdir/$PRGNAM-$src" "$path" || exit 1
		else
			# Only linking required
			ln -sf "$srcdir/$src" "$path" || exit 1
		fi
	fi
}

get-package () {
	check-source
	if [ $valid -ne 1 ]; then
		# Download the source
		download-source
	else
		echo "Source: $src present."
	fi
}

check-built-package () {
	# Source the .info file to get the package version 
	if [ -f "$path/$package.info" ]; then
		. "$path/$package.info"
	else
		VERSION="UNKNOWN"
	fi
	# Check if package has already been built
	if [ -f "/tmp/$package"*-"$VERSION"* ] 2>/dev/null || [ -f "$outdir/$package"*-"$VERSION"* ] 2>/dev/null; then
		built=1
		echo "Package: $package($VERSION) already built."
	else
		built=0
	fi
}

process-built-package () {
	check-built-package
	if [ $built -eq 0 ]; then
		build-package
	fi
}

build-package () {
	check-built-package	
	# Check for SlackBuild
	if [ -f "$path/$package.SlackBuild" ]; then
		chmod +x "$path/$package.SlackBuild" || exit 1
	else
		echo "asbt: $path/$package.SlackBuild N/A"
		exit 1
	fi
	# Check for built package
	if [ $built -eq 1 ]; then
		echo "Re-building $package"
	else	
		echo "Building $package"
	fi
	# Fix CWD to include path to package
	sed -i 's/CWD=$(pwd)/CWD=${CWD:-$(pwd)}/' "$path/$package.SlackBuild" || exit 1
	# Check if outdir is present (if yes, built package is saved there)
	if [ -z "$outdir" ]; then
		sudo -k CWD="$path" "$path/$package.SlackBuild" || exit 1
	else
		sudo -k OUTPUT="$outdir" CWD="$path" "$path/$package.SlackBuild" || exit 1
	fi 
	# After building revert the slackbuild to original state
	sed -i 's/CWD=${CWD:-$(pwd)}/CWD=$(pwd)/' "$path/$package.SlackBuild"
}

install-package () {
	# Check if package present
	if [[ `ls "$outdir/$package"* 2> /dev/null` ]] || [[ `ls "/tmp/$package"* 2> /dev/null` ]]; then
		pkgpath=`ls -t "/tmp/$package"* "$outdir/$package"* 2> /dev/null | head -n 1`
		echo "Installing $package"
		sudo -k /sbin/installpkg "$pkgpath"
	else
		echo "Package: $package N/A"
		exit 1
	fi 
}

upgrade-package () {
	# Check if package present
	if [[ `ls "$outdir/$package"* 2> /dev/null` ]] || [[ `ls "/tmp/$package"* 2> /dev/null` ]]; then
		pkgpath=`ls -t "/tmp/$package"* "$outdir/$package"* 2> /dev/null | head -n 1`
		echo "Upgrading $package"
		sudo -k /sbin/upgradepkg "$pkgpath"
	else
		echo "Package: $package N/A"
		exit 1
	fi 
}

# Options
case "$1" in
search|-s)
	check-input
	check-repo
	check-option "$2"
	find -L "$repodir" -maxdepth 2 -mindepth 1 -type d -iname "*$package*" -printf "%P\n"
	;;
query|-q)
	check-input
	check-option "$2"
	find "/var/log/packages" -maxdepth 1 -type f -iname "*$package*" -printf "%f\n" | sort
	;;
find|-f)
	check-input
	check-repo
	check-option "$2"
	echo "Present in slackbuilds repository:"
	find -L "$repodir" -mindepth 2 -maxdepth 2 -type d -iname "*$package*" -printf "%P\n"
	echo -e "\nInstalled:"
	find "/var/log/packages" -maxdepth 1 -type f -iname "*$package*_SBo" -printf "%f\n"
	;;
info|-i)
	check-input
	check-repo
	check-option "$2"
	get-path
	get-content "$path/$package.info"
	;;
readme|-r)
	check-input
	check-repo
	check-option "$2"
	get-path
	get-content "$path/README"
	;;
view|-v)
	check-input
	check-repo
	check-option "$2"
	get-path
	if [ -e $editor ]; then
		$editor "$path/$package.SlackBuild"
	else
		less "$path/$package.Slackbuild"
	fi
	;;
desc|-d)
	check-input
	check-repo
	check-option "$2"
	get-path
	get-content "$path/slack-desc" | grep "$package" | cut -f 2- -d ":"
	;;
list|-l)
	check-input
	check-repo
	check-option "$2"
	get-path
	ls $path
	;;
longlist|-L)
	check-input
	check-repo
	check-option "$2"
	get-path
	ls -l $path
	;;
enlist|-e)
	check-input
	check-repo
	check-option "$2"
	for i in $(find -L "$repodir" -type f -name "*.info");
		do (grep "$package" $i && printf "@ $i\n\n"); 
	done
	;;
track|-t)
	check-input
	check-option "$2"
	echo "Source:"
	find "$srcdir" -maxdepth 1 -type f -iname "$package*"
	echo -e "\nBuilt:"
	find "$outdir" -maxdepth 1 -type f -iname "$package*"
	find "/tmp" -maxdepth 1 -type f -iname "$package*"
	;;
goto|-g)
	check-input
	check-repo
	check-option "$2"
	get-path
	if [ "$TERM" == "linux" ]; then
		echo "Goto: N/A"
		exit 1
	fi
	if [ -e /usr/bin/xfce4-terminal ]; then
        	xfce4-terminal --working-directory="$path"
	elif [ -e /usr/bin/konsole ]; then
		konsole --workdir "$path"
	elif [ -e /usr/bin/xterm ]; then
		xterm -e 'cd "$path" && /bin/bash'
	else
		echo "Goto: N/A"
		exit 1
	fi
	;;
get|-G)
	check-input
	check-repo
	check-option "$2"
	get-path
	get-package
	if [ $valid -eq 1 ]; then
		echo -n "Re-download? [y/N]: "
		read -e choice
		if [ "$choice" == y ] || [ "$choice" == Y ]; then
			download-source
		fi
	fi
	;;
build|-B)
	check-input
	check-repo
	check-option "$2"
	get-path
	build-package
	;;
install|-I)
	check-input
	check-option "$2"
	install-package
	;;
upgrade|-U)
	check-input
	check-option "$2"
	upgrade-package
	;; 
remove|-R)
	check-input
	check-option "$2"
	# Check if package is installed 
	if [ -f "/var/log/packages/$package"* ]; then
		echo "Removing $package"
		rpkg=`ls "/var/log/packages/$package"*`
		sudo -k /sbin/removepkg "$rpkg"
	else
		echo "Package: $package N/A"
		exit 1
	fi
	;;
process|-P)
	check-input
	check-repo
	check-option "$2"
	get-path
	echo "Processing $package..."
	get-package || exit 1
	process-built-package || exit 1
	# Check if package is already installed
	if [ -f "/var/log/packages/$package"* ]; then
		upgrade-package
	elif [ ! -f "/var/log/packages/$package"* ]; then
		install-package
	else
		echo "N/A"
		exit 1
	fi
	;;
details|-D)
	check-input
	check-option "$2"
	if [ -f /var/log/packages/$package* ]; then
		less /var/log/packages/$package*
	else
		echo "Details about package $package N/A"
		exit 1
	fi
	;;
tidy|-T)
	# Check arguments
	if [ $# -gt 3 ]; then
		echo "Invalid syntax. Correct syntax for this option is:"
		echo "asbt -T [--dry-run] <src> or asbt -T [--dry-run] <pkg>"
		exit 1
	fi

	if [ "$2" == "--dry-run" ]; then
		flag=1
		# Shift argument left so that cleanup is handled same whether dry-run is specified or not.
		shift
	else
		flag=0
	fi

	if [ "$2" == "src" ]; then
		check-src-dir
		# Now find the names of the packages (irrespective of the version) and sort it and remove non-unique entries
		for i in $(find "$srcdir" -maxdepth 1 -type f -printf "%f\n" | rev | cut -d "-" -f 2- | rev | sort -u); do
			# Remove all but the 3 latest (by date) source packages
			if [ $flag -eq 1 ]; then
				# Dry-run; only display packages to be deleted
				ls -td -1 "$srcdir/$i"* | tail -n +4
			else
				rm -v $(ls -td -1 "$srcdir/$i"* | tail -n +4) 2>/dev/null
			fi
		done
	elif [ "$2" == "pkg" ]; then
		check-out-dir
		for i in $(find "$outdir" -maxdepth 1 -type f -printf "%f\n" | rev | cut -d "-" -f 4- | rev | sort -u); do
			if [ $flag -eq 1 ]; then
				ls -td -1 "$outdir/$i"* | tail -n +4
			else
				rm -v $(ls -td -1 "$outdir/$i"* | tail -n +4) 2>/dev/null
			fi
		done
	else
		echo "Unrecognised option for tidy. See the man page for more info."
		exit 1
	fi
	;;
--update|-u)
	if [ -z "$gitdir" ]; then
		echo "Git directory not specified."
		exit 1
	fi
	if [ -d "$gitdir" ]; then
		echo "Updating git repo $gitdir"
		git --git-dir="$gitdir" --work-tree="$gitdir/.." pull origin master || exit 1
	else
		echo "Git directory $gitdir doesnt exist.."
		exit 1
	fi
	;;
--all|-a)
	find "/var/log/packages" -name "*_SBo*" -printf "%f\n" ;;
--check|-c)
	check-repo
	for i in /var/log/packages/*_SBo*; do
		package=$(basename "$i" | rev | cut -d "-" -f 4- | rev)
		pkgver=$(basename "$i" | rev | cut -d "-" -f 3 | rev)
		path=$(find -L "$repodir" -maxdepth 2 -type d -name "$package")
		if [ -f "$path/$package.info" ]; then
			. "$path/$package.info"
		else
			# For packages not present in slackbuilds repo
			VERSION="$pkgver"
		fi
		if [[ ! "$pkgver" == "$VERSION" ]]; then
			printf "$package:\t$pkgver -> $VERSION\n"
		fi
	done
	;;
--setup|-S)
	setup ;;
--version|-V)
        echo -e "asbt version-$ver" ;;
--changelog|-C)
	check-repo
	if [ -f "$repodir/ChangeLog.txt" ]; then
		less "$repodir/ChangeLog.txt"
	else
		echo "$repodir/ChangeLog.txt N/A"
		exit 1
	fi
	;;
--help|-h|*)
	if [ -d "$repodir" ]; then
		repo="$repodir"
	else
		repo="N/A"
	fi
	cat << EOF 
Usage: asbt <option> [package]
Options-
	[search,-s]	[query,-q]	[find,-f]
	[info,-i]	[readme,-r]	[desc,-d]
	[view,-v]	[goto,-g]	[list,-l]
	[track,-t]	[longlist,-L]	[enlist,-e]
	[get,-G]	[build,-B]	[install,-I]
	[upgrade,-U]	[remove,-R]	[process,-P]
	[details,-D]	[tidy,-T]	[--update,-u]
	[--check,-c]	[--all,-a]	[--help,-h]
	[--version,-V]	[--setup,-S]	[--changelog,-C]
	
Using repository: $repo
For more info, see the man page and/or the README.
EOF
	unset repo
       ;;
esac

# Cleanup
unset repodir
unset package
unset path
unset srcdir
unset outdir
unset pkgname
unset pkgpath
unset link
unset arch
unset conf
unset rpkg
unset src
unset pkgnam
unset md5
unset valid
unset built
unset editor
unset choice
exit 0
