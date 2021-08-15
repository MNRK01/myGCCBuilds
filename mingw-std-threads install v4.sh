# this script assumes that a working installation of mingw_std_threads-a.b.c are available for i686 and x86_64.
# this script also assumes that old patches are available in ~/Scripts.
# see "~/Scripts/mingw_std_threads build instructions.txt" for details on how to build mingw_std_threads

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

# delete any existing mingw_std_threads directory and clone Jamaika-github/mingw_std_threads git repository
cd /c/OSRC/
( [[ -e mingw_std_threads_Jamaika ]] || mkdir mingw_std_threads_Jamaika ) && cd mingw_std_threads_Jamaika
[[ -e mingw_std_threads ]] && rm -rf mingw_std_threads
echo "Cloning mingw_std_threads into mingw_std_threads_Jamaika"
# clone the entire git repository and not just the main branch!
# git clone --branch main https://github.com/Jamaika1/mingw_std_threads
git clone https://github.com/Jamaika1/mingw_std_threads
echo "-----------------------"

# location of the mingw_std_threads library
MINGW_STD_THREADS_DIR="/c/OSRC/mingw_std_threads_Jamaika/mingw_std_threads"
cd $MINGW_STD_THREADS_DIR

# capture `git status` while we are in the $MINGW_STD_THREADS_DIR directory
GITSTATUS=$(git status)

# find location of the headers as it is buried in a directory structure that mimics the one from gcc
# except that it has the gcc version built into the directory names and this could change in the future
HEADER_DIR=$(find $MINGW_STD_THREADS_DIR -name thread -print)
HEADER_DIR=$(echo $HEADER_DIR | sed "s/\/thread//")
echo "Headers were found in $HEADER_DIR"
cd $HEADER_DIR && ls -R $HEADER_DIR
echo "-----------------------"

# create a logfile in Jamaika-github directory
LOGFILE=$MINGW_STD_THREADS_DIR/../build.log

# capture $GITSTATUS into the $LOGFILE, note the use of quotes to preserve multiple line endings
echo "$GITSTATUS" > $LOGFILE
echo "-----------------------" >> $LOGFILE

# version of the new gcc
GCC_VER='11.1.0'
# generates a numeric sequence from $GCC_VER without any periods, e.g. 10.1.0 => 1010, which is useful for directory names
GCC_VER_NODOT=${GCC_VER//./}

# mingw-w64 crt runtime version of mingw-w64 and revision of the build
RUNTIME='v9'
REV='rev0'

# define targets to make, any posix builds already have functional C++11 via pthreads, so they will not be fixed
ALLTARGS=(
	          "i686-win32-sjlj-x32"
	          "x86_64-win32-seh-x64"
	     )

# install patches for $ALLTARGS
for targ in "${ALLTARGS[@]}"
do
	echo "Installing mingw_std_threads_Jamaika/mingw_std_threads for $targ"
	echo "Installing mingw_std_threads_Jamaika/mingw_std_threads for $targ" >> $LOGFILE
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

    # location of GCC C++ include directory
    GCC_ROOT="/c/OSRC/gcc-build/msys64/home/arkay7777/mingw-gcc-$GCC_VER/$ARCH-$GCC_VER_NODOT-$THREAD-$EXCEPT-rt_$RUNTIME-$REV/mingw$BITS"
    GCC_INCL="$GCC_ROOT/lib/gcc/${ARCH}-w64-mingw32/${GCC_VER}/include/c++"
    [[ -d $GCC_INCL ]] || die "$GCC_INCL directory does not exist. Exiting."

    # add gcc to the path
    export PATH=$GCC_ROOT/bin:$OLDPATH

    # add gcc info the logfile
    gcc -v >> $LOGFILE 2>&1
    echo "gcc C++ include directory is $GCC_INCL" >> $LOGFILE

    # copy other header files, e.g. mingw.thread.h, from mingw_std_threads to $GCC_INCL
    # https://stackoverflow.com/questions/33903954/changing-suffix-on-bash-file-backup
    echo "Copying C++11 and other *.h headers to $GCC_INCL"
    cp --verbose --backup=numbered -rp * $GCC_INCL >> $LOGFILE

    echo "mingw_std_threads installed in $GCC_INCL."

    # add information to buildinfo.txt
    echo "Adding build information to gcc build-info.txt"
    echo "name         : mingw_std_threads from Jamaika1"                               >> $GCC_ROOT/build-info.txt
    echo "type         : .git"                                                          >> $GCC_ROOT/build-info.txt
    echo "version      : main branch"                                                   >> $GCC_ROOT/build-info.txt
    echo "url          : https://github.com/Jamaika1/mingw_std_threads"                 >> $GCC_ROOT/build-info.txt
    echo "patches      :"                                                               >> $GCC_ROOT/build-info.txt
    echo "configuration: mingw-std-threads install v4.sh"                               >> $GCC_ROOT/build-info.txt
    echo                                                                                >> $GCC_ROOT/build-info.txt
    echo "# **************************************************************************" >> $GCC_ROOT/build-info.txt
    echo                                                                                >> $GCC_ROOT/build-info.txt

    echo "-----------------------" >> $LOGFILE
    echo "-----------------------"
done

echo "Done building. Build took $(($SECONDS - STARTTIME)) seconds"

