# this script assumes that a working installation of mingw-std-threads-a.b.c are available for i686 and x86_64.
# this script also assumes that old patches are available in ~/Scripts.
# see "~/Scripts/mingw-std-threads build instructions.txt" for details on how to build mingw-std-threads

# **************************************************************************
# set up

# from mingw-builds/library/functions.sh
function die {
	# $1 - message on exit
	# $2 - exit code
	local _retcode=1
	[[ -n $2 ]] && _retcode=$2
	echo
	>&2 echo $1
	exit $_retcode
}

# version of the old gcc versions that is in <condition_variable>, <mutex>, <future>, <thread> and <shared_mutex>
GCC_OLD='9.3.0'
# generates a numeric sequence from $GCC_OLD without any periods, e.g. 9.3.0 => 930, which is useful for directory names
GCC_OLD_DIR=${GCC_OLD//./}
# version of the new gcc
GCC_NEW='10.1.0'
# generates a numeric sequence from $GCC_NEW without any periods, e.g. 10.1.0 => 1010, which is useful for directory names
GCC_NEW_DIR=${GCC_NEW//./}

# location where the patches reside
SCRIPT_DIR='/c/Users/arkay7777/Documents/'
[[ -d $SCRIPT_DIR ]] || die "Script directory does not exist. Exiting."
# prefix for the mingw-std-threads-a.b.c directories
MINGW_STD_THREADS_DIR_VER='1.0.0'
MINGW_STD_THREADS_DIR_PREFIX="/c/Software/mingw-std-threads-$MINGW_STD_THREADS_DIR_VER"

# mingw-w64 crt runtime version of mingw-w64 and revision of the build
RUNTIME='v7'
REV='rev0'

# **************************************************************************
# i686 builds

# create mingw-std-threads for i686
BUILD_ARCH='i686'

# create a new patch file for $GCC_NEW
[[ -e $SCRIPT_DIR/mingw-std-threads-$BUILD_ARCH-w64-mingw32-$GCC_OLD_DIR.patch ]] || die "Mingw-std-threads patch for $BUILD_ARCH not found. Exiting."
sed -e "s/$GCC_OLD/$GCC_NEW/" $SCRIPT_DIR/mingw-std-threads-$BUILD_ARCH-w64-mingw32-$GCC_OLD_DIR.patch > $SCRIPT_DIR/mingw-std-threads-$BUILD_ARCH-w64-mingw32-$GCC_NEW_DIR.patch
echo "$SCRIPT_DIR/mingw-std-threads-$BUILD_ARCH-w64-mingw32-$GCC_NEW_DIR.patch file generated."

# cd to the mingw-std-threads-a.b.c for i686
[[ -d $MINGW_STD_THREADS_DIR_PREFIX-$BUILD_ARCH ]] || die "$MINGW_STD_THREADS_DIR_PREFIX-$BUILD_ARCH directory does not exist. Exiting."
cd $MINGW_STD_THREADS_DIR_PREFIX-$BUILD_ARCH/
# remove the old C++ header files
rm condition_variable future mutex shared_mutex thread
# and patch with the newly generated patch for $GCC_NEW version
# patch -uN --verbose --dry-run --binary -d . < $SCRIPT_DIR/mingw-std-threads-$BUILD_ARCH-w64-mingw32-$GCC_NEW_DIR.patch
patch -uN --verbose --binary -d . < $SCRIPT_DIR/mingw-std-threads-$BUILD_ARCH-w64-mingw32-$GCC_NEW_DIR.patch
echo "$MINGW_STD_THREADS_DIR_PREFIX-$BUILD_ARCH patched."

# **************************************************************************
# install for i686-posix-sjlj

# location of GCC opt/include libraries for i686 posix-sjlj
GCC_OPT_INCL="/c/Software/gcc-build/msys64/home/arkay7777/mingw-gcc-$GCC_NEW/$BUILD_ARCH-$GCC_NEW_DIR-posix-sjlj-rt_$RUNTIME-$REV/mingw32/opt/include"
[[ -d $GCC_OPT_INCL ]] || die "$GCC_OPT_INCL directory does not exist. Exiting."
# delete $GCC_OPT_INCL/mingw-std-threads if it exists and make the mingw-std-threads directory
[[ -d $GCC_OPT_INCL/mingw-std-threads ]] && rm -rf $GCC_OPT_INCL/mingw-std-threads
mkdir $GCC_OPT_INCL/mingw-std-threads
# install mingw-std-threads
cp -ipr $MINGW_STD_THREADS_DIR_PREFIX-$BUILD_ARCH/* $GCC_OPT_INCL/mingw-std-threads
echo "mingw-std-threads installed in $GCC_OPT_INCL/mingw-std-threads."
# add information to buildinfo.txt
echo "name         : mingw-std-threads-$MINGW_STD_THREADS_DIR_VER" >> $GCC_OPT_INCL/../../build-info.txt
echo "type         : .zip"                                         >> $GCC_OPT_INCL/../../build-info.txt
echo "version      : $MINGW_STD_THREADS_DIR_VER"                   >> $GCC_OPT_INCL/../../build-info.txt
echo "url          : https://github.com/meganz/mingw-std-threads"  >> $GCC_OPT_INCL/../../build-info.txt
echo "patches      :"                                              >> $GCC_OPT_INCL/../../build-info.txt
echo "configuration: mingw-std-threads install.sh"                 >> $GCC_OPT_INCL/../../build-info.txt
echo                                                               >> $GCC_OPT_INCL/../../build-info.txt
echo "# **************************************************************************" >> $GCC_OPT_INCL/../../build-info.txt
echo                                                               >> $GCC_OPT_INCL/../../build-info.txt

# **************************************************************************
# install for i686-win32-sjlj

# location of GCC opt/include libraries for i686 win32-sjlj
 GCC_OPT_INCL="/c/Software/gcc-build/msys64/home/arkay7777/mingw-gcc-$GCC_NEW/$BUILD_ARCH-$GCC_NEW_DIR-win32-sjlj-rt_$RUNTIME-$REV/mingw32/opt/include"
[[ -d $GCC_OPT_INCL ]] || die "$GCC_OPT_INCL directory does not exist. Exiting."
# delete $GCC_OPT_INCL/mingw-std-threads if it exists and make the mingw-std-threads directory
[[ -d $GCC_OPT_INCL/mingw-std-threads ]] && rm -rf $GCC_OPT_INCL/mingw-std-threads
mkdir $GCC_OPT_INCL/mingw-std-threads
# install mingw-std-threads
cp -ipr $MINGW_STD_THREADS_DIR_PREFIX-$BUILD_ARCH/* $GCC_OPT_INCL/mingw-std-threads
echo "mingw-std-threads installed in $GCC_OPT_INCL/mingw-std-threads."
echo "$MINGW_STD_THREADS_DIR_PREFIX-$BUILD_ARCH patched."
# add information to buildinfo.txt
echo "name         : mingw-std-threads-$MINGW_STD_THREADS_DIR_VER" >> $GCC_OPT_INCL/../../build-info.txt
echo "type         : .zip"                                         >> $GCC_OPT_INCL/../../build-info.txt
echo "version      : $MINGW_STD_THREADS_DIR_VER"                   >> $GCC_OPT_INCL/../../build-info.txt
echo "url          : https://github.com/meganz/mingw-std-threads"  >> $GCC_OPT_INCL/../../build-info.txt
echo "patches      :"                                              >> $GCC_OPT_INCL/../../build-info.txt
echo "configuration: mingw-std-threads install.sh"                 >> $GCC_OPT_INCL/../../build-info.txt
echo                                                               >> $GCC_OPT_INCL/../../build-info.txt
echo "# **************************************************************************" >> $GCC_OPT_INCL/../../build-info.txt
echo                                                               >> $GCC_OPT_INCL/../../build-info.txt

# **************************************************************************
# x86_64 builds

# create mingw-std-threads for x86_64
BUILD_ARCH='x86_64'

# create a new patch file for $GCC_NEW
[[ -e $SCRIPT_DIR/mingw-std-threads-$BUILD_ARCH-w64-mingw32-$GCC_OLD_DIR.patch ]] || die "Mingw-std-threads patch for $BUILD_ARCH not found. Exiting."
sed -e "s/$GCC_OLD/$GCC_NEW/" $SCRIPT_DIR/mingw-std-threads-$BUILD_ARCH-w64-mingw32-$GCC_OLD_DIR.patch > $SCRIPT_DIR/mingw-std-threads-$BUILD_ARCH-w64-mingw32-$GCC_NEW_DIR.patch
echo "$SCRIPT_DIR/mingw-std-threads-$BUILD_ARCH-w64-mingw32-$GCC_NEW_DIR.patch file generated."

# cd to the mingw-std-threads-a.b.c for x86_64
[[ -d $MINGW_STD_THREADS_DIR_PREFIX-$BUILD_ARCH ]] || die "$MINGW_STD_THREADS_DIR_PREFIX-$BUILD_ARCH directory does not exist. Exiting."
cd $MINGW_STD_THREADS_DIR_PREFIX-$BUILD_ARCH/
# remove the old C++ header files
rm condition_variable future mutex shared_mutex thread
# and patch with the newly generated patch for $GCC_NEW version
# patch -uN --verbose --dry-run --binary -d . < $SCRIPT_DIR/mingw-std-threads-$BUILD_ARCH-w64-mingw32-$GCC_NEW_DIR.patch
patch -uN --verbose --binary -d . < $SCRIPT_DIR/mingw-std-threads-$BUILD_ARCH-w64-mingw32-$GCC_NEW_DIR.patch

# **************************************************************************
# install for x86_64-posix-seh

# location of GCC opt/include libraries for x86_64 posix-seh
GCC_OPT_INCL="/c/Software/gcc-build/msys64/home/arkay7777/mingw-gcc-$GCC_NEW/$BUILD_ARCH-$GCC_NEW_DIR-posix-seh-rt_$RUNTIME-$REV/mingw64/opt/include"
[[ -d $GCC_OPT_INCL ]] || die "$GCC_OPT_INCL directory does not exist. Exiting."
# delete $GCC_OPT_INCL/mingw-std-threads if it exists and make the mingw-std-threads directory
[[ -d $GCC_OPT_INCL/mingw-std-threads ]] && rm -rf $GCC_OPT_INCL/mingw-std-threads
mkdir $GCC_OPT_INCL/mingw-std-threads
# install mingw-std-threads
cp -ipr $MINGW_STD_THREADS_DIR_PREFIX-$BUILD_ARCH/* $GCC_OPT_INCL/mingw-std-threads
echo "mingw-std-threads installed in $GCC_OPT_INCL/mingw-std-threads."
# add information to buildinfo.txt
echo "name         : mingw-std-threads-$MINGW_STD_THREADS_DIR_VER" >> $GCC_OPT_INCL/../../build-info.txt
echo "type         : .zip"                                         >> $GCC_OPT_INCL/../../build-info.txt
echo "version      : $MINGW_STD_THREADS_DIR_VER"                   >> $GCC_OPT_INCL/../../build-info.txt
echo "url          : https://github.com/meganz/mingw-std-threads"  >> $GCC_OPT_INCL/../../build-info.txt
echo "patches      :"                                              >> $GCC_OPT_INCL/../../build-info.txt
echo "configuration: mingw-std-threads install.sh"                 >> $GCC_OPT_INCL/../../build-info.txt
echo                                                               >> $GCC_OPT_INCL/../../build-info.txt
echo "# **************************************************************************" >> $GCC_OPT_INCL/../../build-info.txt
echo                                                               >> $GCC_OPT_INCL/../../build-info.txt

# **************************************************************************
# install for x86_64-win32-seh

# location of GCC opt/include libraries for x86_64 win32-seh
GCC_OPT_INCL="/c/Software/gcc-build/msys64/home/arkay7777/mingw-gcc-$GCC_NEW/$BUILD_ARCH-$GCC_NEW_DIR-win32-seh-rt_$RUNTIME-$REV/mingw64/opt/include"
[[ -d $GCC_OPT_INCL ]] || die "$GCC_OPT_INCL directory does not exist. Exiting."
# delete $GCC_OPT_INCL/mingw-std-threads if it exists and make the mingw-std-threads directory
[[ -d $GCC_OPT_INCL/mingw-std-threads ]] && rm -rf $GCC_OPT_INCL/mingw-std-threads
mkdir $GCC_OPT_INCL/mingw-std-threads
# install mingw-std-threads
cp -ipr $MINGW_STD_THREADS_DIR_PREFIX-$BUILD_ARCH/* $GCC_OPT_INCL/mingw-std-threads
echo "mingw-std-threads installed in $GCC_OPT_INCL/mingw-std-threads."
# add information to buildinfo.txt
echo "name         : mingw-std-threads-$MINGW_STD_THREADS_DIR_VER" >> $GCC_OPT_INCL/../../build-info.txt
echo "type         : .zip"                                         >> $GCC_OPT_INCL/../../build-info.txt
echo "version      : $MINGW_STD_THREADS_DIR_VER"                   >> $GCC_OPT_INCL/../../build-info.txt
echo "url          : https://github.com/meganz/mingw-std-threads"  >> $GCC_OPT_INCL/../../build-info.txt
echo "patches      :"                                              >> $GCC_OPT_INCL/../../build-info.txt
echo "configuration: mingw-std-threads install.sh"                 >> $GCC_OPT_INCL/../../build-info.txt
echo                                                               >> $GCC_OPT_INCL/../../build-info.txt
echo "# **************************************************************************" >> $GCC_OPT_INCL/../../build-info.txt
echo                                                               >> $GCC_OPT_INCL/../../build-info.txt

