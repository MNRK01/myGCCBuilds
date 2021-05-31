# *********************************************************************************
# set up

STARTTIME=$SECONDS

export HOME=/home/arkay7777

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

# declare variables
GSL_VER="2.6"
GSL_VER_CODE=${GSL_VER//./_}
GCC_VER="10.3.0"
GCC_VER_CODE=${GCC_VER//./}
MINGW_CRT="v8"
REV="rev0"

# record original path
SYSPATH=$PATH

# download and upzip GSL into C:/OSRC/gsl/gsl-${GSL_VER}-src
cd /c/Users/arkay7777/Desktop
if [[ ! -d /c/OSRC/gsl/gsl-${GSL_VER}-src/gsl-${GSL_VER} ]]; then
	# Download GSL from e.g. https://ftp.gnu.org/gnu/gsl/gsl-M.N.tar.gz
	echo "Downloading GSL.";
	[[ -e gsl-${GSL_VER}.tar.gz ]] || wget https://ftp.gnu.org/gnu/gsl/gsl-${GSL_VER}.tar.gz;
	# extract GSL to /c/OSRC/gsl/gsl-${GSL_VER}-src
	echo "Unzipping GSL.";
	[[ -e /c/OSRC/gsl ]] || mkdir /c/OSRC/gsl;
	cd /c/OSRC/gsl;
	7z x -aoa /c/Users/arkay7777/Desktop/gsl-${GSL_VER}.tar.gz && 7z x -o/c/OSRC/gsl/gsl-${GSL_VER}-src -aoa gsl-${GSL_VER}.tar 1>/dev/null
	[[ -e gsl-${GSL_VER}.tar ]] && rm gsl-${GSL_VER}.tar
fi
cd /c/OSRC/gsl/gsl-${GSL_VER}-src/gsl-${GSL_VER} || die "Unzip was not successful"
echo "------------------------------"

# define targets to make
ALLTARGS=(
	          "i686-posix-sjlj-x32"
	          "i686-posix-sjlj-x64"
	          "i686-win32-sjlj-x32"
	          "i686-win32-sjlj-x64"
	          "x86_64-posix-seh-x64"
	          "x86_64-win32-seh-x64"
	     )

for targ in "${ALLTARGS[@]}"
do
	echo "Building for $targ"
    cd /c/OSRC/gsl/gsl-${GSL_VER}-src/gsl-${GSL_VER}
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

	# define directory to store gcc that is being built
	GSL_DIR=/c/OSRC/gsl/gsl_${GSL_VER}_gcc${GCC_VER_CODE}_${THREAD}_${EXCEPT}_x${BITS}
	# remove any existing ${GSL_DIR} and create a new one
    [[ -e ${GSL_DIR} ]] && rm -rf ${GSL_DIR}
	mkdir -p ${GSL_DIR} || die "Could not build ${GSL_DIR}"

	# define a log file and begin logging
	LOGFILE=${GSL_DIR}/build.log
    [[ -e $LOGFILE ]] && rm $LOGFILE
	echo "Building ${GSL_DIR}"
	echo "Building ${GSL_DIR}" >> $LOGFILE 2>&1
	echo "------------------------------" >> $LOGFILE 2>&1

	# define mingw32 or mingw64 for where to find gcc
	if [[ $ARCH == "i686" ]]; then
	    MINGW32OR64="mingw32"
	else
	    MINGW32OR64="mingw64"
	fi
	# setup path for gcc to be used
    GCC_PATH=/c/OSRC/gcc-build/msys64/home/arkay7777/mingw-gcc-${GCC_VER}/${ARCH}-${GCC_VER_CODE}-${THREAD}-${EXCEPT}-rt_${MINGW_CRT}-${REV}/${MINGW32OR64}
	export PATH=${GCC_PATH}/bin:${SYSPATH}
	echo $PATH >> $LOGFILE

	# log gcc info into logfile
	gcc -v >> $LOGFILE 2>&1
	echo "------------------------------" >> $LOGFILE 2>&1

    # define target bit model through CFLAGS and suppress the -g option
    export CFLAGS="-m$BITS -O2"
    # suppress -g for the linker
    export LDFLAGS="-O2"
    
	# configure gsl
    echo "Configuring..."
	./configure --prefix=${GSL_DIR} --enable-static --disable-shared >> $LOGFILE 2>&1
	echo "------------------------------" >> $LOGFILE 2>&1

    # building, testing, installing and cleaning
    echo "Building..."
    make -j 4 >> $LOGFILE
	echo "------------------------------" >> $LOGFILE 2>&1
    echo "Testing..."
    make -j 4 test >> $LOGFILE
	echo "------------------------------" >> $LOGFILE 2>&1
    echo "Installing..."
    make -j 4 install >> $LOGFILE
	echo "------------------------------" >> $LOGFILE 2>&1
    echo "Cleaning..."
    make -j 4 clean >> $LOGFILE
	echo "------------------------------" >> $LOGFILE 2>&1

    # test if the i686-{posix|win32}-sjlj-x{32|64} builds have identical include directories
    if [[ $ARCH == "i686" ]] && [[ $BITS == "64" ]]; then
        DIRx64=${GSL_DIR}
        DIRx32=${DIRx64/x64/x32}
        DIFF_FILE=/c/OSRC/gsl/gsl-${GSL_VER}-src/gsl_${GSL_VER}_gcc${GCC_VER_CODE}_${THREAD}_${EXCEPT}.diff
        diff -ur ${DIRx32}/include/ ${DIRx64}/include/ > $DIFF_FILE
        [ `ls -l $DIFF_FILE | awk '{print $5}'` -ne 0 ] && die "**Check $DIFF_FILE for diferences in the include directories!**"
    fi

    # install the just-built icu include and lib dirs to the $GCC_PATH/opt
    echo "Installing to ${GCC_PATH}/opt"
    cd ${GSL_DIR}
    cp -rpT include $GCC_PATH/opt/include/gsl-${GSL_VER_CODE}/
    if ([[ $ARCH == "i686" ]] && [[ $BITS == "32" ]]) || [[ $ARCH == "x86_64" ]]; then
        cp -rpT lib $GCC_PATH/opt/lib/gsl-${GSL_VER_CODE}/
        # cp -rpT bin $GCC_PATH/opt/bin/gsl-${GSL_VER_CODE}/
        cp -rpT share $GCC_PATH/opt/share/gsl-${GSL_VER_CODE}/
    elif [[ $ARCH == "i686" ]] && [[ $BITS == "64" ]]; then
        cp -rpT lib $GCC_PATH/opt/lib/gsl-${GSL_VER_CODE}/lib64/
        # cp -rpT bin $GCC_PATH/opt/bin/gsl-${GSL_VER_CODE}/bin64/
        # don't copy i686-x64 multilib share since it is documentation
        # cp -rpT share $GCC_PATH/opt/share/gsl-${GSL_VER_CODE}/lib64/
    fi
    # no need to record the build log
    # cp -p build.log $GCC_PATH/opt/include/gsl-${GSL_VER_CODE}/build.log

    # add information to buildinfo.txt
    echo "Writing build info to ${GCC_PATH}/build-info.txt"
    echo "name         : gsl-${GSL_VER}"                                                                                             >> $GCC_PATH/build-info.txt
    echo "type         : .tar.gz"                                                                                                    >> $GCC_PATH/build-info.txt
    echo "version      : $GSL_VER"                                                                                                   >> $GCC_PATH/build-info.txt
    echo "url          : https://ftp.gnu.org/gnu/gsl/gsl-${GSL_VER}.tar.gz"                                                          >> $GCC_PATH/build-info.txt
    echo "patches      : "                                                                                                           >> $GCC_PATH/build-info.txt
    if [[ $BITS == "32" ]]; then
        echo "configuration: gsl build.sh, 32-bit build"                                                                             >> $GCC_PATH/build-info.txt
    elif [[ $BITS == "64" ]]; then
        echo "configuration: gsl build.sh, 64-bit build"                                                                             >> $GCC_PATH/build-info.txt
    fi
    echo                                                                                                                             >> $GCC_PATH/build-info.txt
    echo "# **************************************************************************"                                              >> $GCC_PATH/build-info.txt
    echo                                                                                                                             >> $GCC_PATH/build-info.txt

	echo "------------------------------"
done

echo "Done building. Build took $(($SECONDS - STARTTIME)) seconds"

