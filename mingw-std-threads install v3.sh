# this script assumes that a working installation of mingw-std-threads-a.b.c are available for i686 and x86_64.
# this script also assumes that old patches are available in ~/Scripts.
# see "~/Scripts/mingw-std-threads build instructions.txt" for details on how to build mingw-std-threads

# **************************************************************************
# set up

STARTTIME=$SECONDS

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

# store original path
OLDPATH=$PATH

# delete any existing mingw-std-threads directory and clone mingw-std-threads git repository
cd /c/Software
[[ -e mingw-std-threads ]] && rm -rf mingw-std-threads
echo "Cloning mingw-std-threads"
git clone --branch master https://github.com/meganz/mingw-std-threads
echo "-----------------------"

# location of the mingw-std-threads library
MINGW_STD_THREADS_DIR="/c/OSRC/mingw-std-threads"

# create a logfile
LOGFILE=$MINGW_STD_THREADS_DIR/build.log

# patch $gcc.WaitForExit() so that it does not wait for ever
cd $MINGW_STD_THREADS_DIR
echo "Patching Generate-StdLikeHeaders.ps1"
echo "Patching Generate-StdLikeHeaders.ps1" > $LOGFILE
echo "-----------------------" >> $LOGFILE
sed -i.orig -e 's/\$gcc.WaitForExit()/\$gcc.WaitForExit(3000)/g' utility_scripts/Generate-StdLikeHeaders.ps1
echo "-----------------------"

# version of the new gcc
GCC_VER='10.3.0'
# generates a numeric sequence from $GCC_VER without any periods, e.g. 10.1.0 => 1010, which is useful for directory names
GCC_VER_NODOT=${GCC_VER//./}

# mingw-w64 crt runtime version of mingw-w64 and revision of the build
RUNTIME='v8'
REV='rev0'

# define targets to make
ALLTARGS=(
	          "i686-posix-sjlj-x32"
	          "i686-win32-sjlj-x32"
	          "x86_64-posix-seh-x64"
	          "x86_64-win32-seh-x64"
	     )

# install patches for $ALLTARGS
for targ in "${ALLTARGS[@]}"
do
	echo "Installing mingw-std-threads for $targ"
	# parse $targ for plataform, thread + exception model and bit model
	if [[ "$targ" =~ (.*)-(.*)-(.*)-x(.*) ]]; then
	    ARCH=${BASH_REMATCH[1]}
	    # echo $ARCH
	    THREAD=${BASH_REMATCH[2]}
	    # echo $THREAD
	    EXCEPT=${BASH_REMATCH[3]}
	    # echo $EXCEPT
	    BITS=${BASH_REMATCH[4]}
	    # echo $BITS
	else
	    echo "No match for $targ. Exiting."
	    exit
	fi

    # location of GCC opt/include libraries
    GCC_ROOT="/c/OSRC/gcc-build/msys64/home/arkay7777/mingw-gcc-$GCC_VER/$ARCH-$GCC_VER_NODOT-$THREAD-$EXCEPT-rt_$RUNTIME-$REV/mingw$BITS"
    GCC_OPT_INCL="$GCC_ROOT/opt/include"
    [[ -d $GCC_OPT_INCL ]] || die "$GCC_OPT_INCL directory does not exist. Exiting."
    # delete $GCC_OPT_INCL/mingw-std-threads if it exists and make the mingw-std-threads directory
    MINGW_STD_THREADS_INSTALL_DIR=$GCC_OPT_INCL/mingw-std-threads
    [[ -d $MINGW_STD_THREADS_INSTALL_DIR ]] && rm -rf $MINGW_STD_THREADS_INSTALL_DIR
    mkdir $MINGW_STD_THREADS_INSTALL_DIR

    # add gcc to the path
    export PATH=$GCC_ROOT/bin:$OLDPATH

    # add gcc info the logfile
    gcc -v >> $LOGFILE 2>&1

    # generate the headers using a provided powershell utility script
    echo "Generating mingw-std-threads headers"
    powershell.exe -File $MINGW_STD_THREADS_DIR/utility_scripts/Generate-StdLikeHeaders.ps1 -DestinationFolder "$MINGW_STD_THREADS_INSTALL_DIR" >> $LOGFILE 2>&1

    # copy other header files, e.g. mingw.thread.h, from mingw-std-threads to $MINGW_STD_THREADS_DIR
    echo "Copying other *.h headers, README.md and LICENSE to $MINGW_STD_THREADS_DIR"
    cp -pv $MINGW_STD_THREADS_DIR/{*.h,README.md,LICENSE} $MINGW_STD_THREADS_INSTALL_DIR >> $LOGFILE

    echo "mingw-std-threads installed in $GCC_OPT_INCL/mingw-std-threads."

    # create a sed friendly Windows version of $GCC_ROOT by using cygpath -w and then replacing "\" with "\\"
    GCC_ROOT_SED=$(cygpath.exe -w $GCC_ROOT | sed -e 's/\\/\\\\/g')
    # create a sed friendly MINGW_STD_THREADS_DIR by using cygpath -w and then replacing "\" with "\\"
    MINGW_STD_THREADS_DIR_SED=$(cygpath.exe -w $MINGW_STD_THREADS_DIR | sed -e 's/\\/\\\\/g')
    # now edit the generated headers in place to remove hardcoded paths
    cd $MINGW_STD_THREADS_INSTALL_DIR
    echo "Changing absolute paths to relative paths in the generated headers"
    sed -i -e 's/'"$GCC_ROOT_SED"'/..\\..\\../g' condition_variable
    sed -i -e 's/'"$GCC_ROOT_SED"'/..\\..\\../g' future
    sed -i -e 's/'"$GCC_ROOT_SED"'/..\\..\\../g' mutex
    sed -i -e 's/'"$GCC_ROOT_SED"'/..\\..\\../g' shared_mutex
    sed -i -e 's/'"$GCC_ROOT_SED"'/..\\..\\../g' thread
    sed -i -e 's/'"$MINGW_STD_THREADS_DIR_SED"'/./g' condition_variable
    sed -i -e 's/'"$MINGW_STD_THREADS_DIR_SED"'/./g' future
    sed -i -e 's/'"$MINGW_STD_THREADS_DIR_SED"'/./g' mutex
    sed -i -e 's/'"$MINGW_STD_THREADS_DIR_SED"'/./g' shared_mutex
    sed -i -e 's/'"$MINGW_STD_THREADS_DIR_SED"'/./g' thread

    # add information to buildinfo.txt
    echo "Adding build information to gcc build-info.txt"
    echo "name         : mingw-std-threads"                            >> $GCC_OPT_INCL/../../build-info.txt
    echo "type         : .git"                                         >> $GCC_OPT_INCL/../../build-info.txt
    echo "version      : master branch"                                >> $GCC_OPT_INCL/../../build-info.txt
    echo "url          : https://github.com/meganz/mingw-std-threads"  >> $GCC_OPT_INCL/../../build-info.txt
    echo "patches      :"                                              >> $GCC_OPT_INCL/../../build-info.txt
    echo "configuration: mingw-std-threads install v3.sh"              >> $GCC_OPT_INCL/../../build-info.txt
    echo                                                               >> $GCC_OPT_INCL/../../build-info.txt
    echo "# **************************************************************************" >> $GCC_OPT_INCL/../../build-info.txt
    echo                                                               >> $GCC_OPT_INCL/../../build-info.txt

    echo "-----------------------" >> $LOGFILE
    echo "-----------------------"
done

echo "Done building. Build took $(($SECONDS - STARTTIME)) seconds"

