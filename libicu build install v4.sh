# this script builds ICU4C libraries and installs them into a mingw-w64 toolset.
# the thread library is github.com/Jamaika1/mingw-std-threads used when thread model is win32.
# *********************************************************************************
# set up

STARTTIME=$SECONDS

export HOME=/home/arkay7777

# record original path
SYSPATH=$PATH

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
# ICU_VER="69.1"
if [[ ! $ICU_VER ]]; then echo "GCC version not declared. Exiting..."; exit 1; fi
ICU_VER_CODE=${ICU_VER/./_}
ICU_VER_URL=${ICU_VER/./-}
# GCC_VER="11.1.0"
if [[ ! $GCC_VER ]]; then echo "GCC version not declared. Exiting..."; exit 1; fi
GCC_VER_CODE=${GCC_VER//./}
# MINGW64_CRT="v9"
if [[ ! $MINGW64_CRT ]]; then echo "Mingw-w64 runtime version not declared. Exiting..."; exit 1; fi
# REV="0"
if [[ ! $REV ]]; then echo "Mingw-w64 GCC revision number not declared. Exiting..."; exit 1; fi

# download and upzip libicu into C:/OSRC/libicu-${ICU_VER_CODE}
cd /c/Users/arkay7777/Desktop
if [[ ! -d /c/OSRC/libicu-${ICU_VER_CODE} ]]; then
    # Download ICU4C from e.g. https://github.com/unicode-org/icu/releases/download/release-NN-X/icu4c-NN_X-src.zip
    echo "Downloading ICU4C.";
    [[ -e icu4c-$ICU_VER_CODE-src.zip ]] || wget https://github.com/unicode-org/icu/releases/download/release-${ICU_VER_URL}/icu4c-${ICU_VER_CODE}-src.zip;
    # extract icu4c to /c/OSRC/libicu-${ICU_VER_CODE}
    echo "Unzipping ICU4C.";
    [[ -e /c/OSRC/libicu-${ICU_VER_CODE} ]] || mkdir /c/OSRC/libicu-${ICU_VER_CODE};
    cd /c/OSRC/libicu-${ICU_VER_CODE};
    unzip -o /c/Users/arkay7777/Desktop/icu4c-$ICU_VER_CODE-src.zip 1> /dev/null;
fi
cd /c/OSRC/libicu-${ICU_VER_CODE}/icu/source || die "Unzip was not successful"

# patch mh-mingw to prevent "s" prefix to static libs and name libicuin.a => libicui18n.a, libicudt.a => libicudata.a
# diff -ur icu-orig/source/config icu/source/config > /c/Users/arkay7777/Documents/libicu-config.patch
echo "Patching ICU4C."
cd /c/OSRC/libicu-${ICU_VER_CODE}
PATCHLOG=/c/OSRC/libicu-${ICU_VER_CODE}/icu/patch.log
PATCH_OUT=$(patch -uN --verbose --binary -d ./icu/source/config < /c/Users/arkay7777/Documents/libicu-config.patch)
if [ $? == 0 ]; then
    # need to quote to output newlines, https://stackoverflow.com/questions/613572/capturing-multiple-line-output-into-a-bash-variable
    echo "$PATCH_OUT" > ${PATCHLOG}
    echo "$PATCH_OUT"
elif [[ $PATCH_OUT =~ 'Reversed (or previously applied) patch detected!' ]]; then
    echo "$PATCH_OUT" > ${PATCHLOG}
    echo "$PATCH_OUT"
    echo "\"libicu-config.patch\" has been previously applied. Patch skipped."
else
    die "\"libicu-config.patch\" failed. Exiting."
fi
echo '------------------------------'

# define targets to make
ALLTARGS=(
	          "i686-posix-sjlj-msvcrt-x32"
	          "i686-posix-sjlj-msvcrt-x64"
	          "x86_64-posix-seh-ucrt-x64"
	     )

# loop through ALLTARGS and build and install libicu
for targ in "${ALLTARGS[@]}"
do
	echo "Building for $targ"
	# parse $targ for plataform, thread + exception model and bit model
	if [[ "$targ" =~ (.*)-(.*)-(.*)-(.*)-x(.*) ]]; then
	    ARCH=${BASH_REMATCH[1]}
	    # echo $ARCH
	    THREAD=${BASH_REMATCH[2]}
	    # echo $THREAD
	    EXCEPT=${BASH_REMATCH[3]}
	    # echo $EXCEPT
	    OSTYPE=${BASH_REMATCH[4]}
	    # echo $OSTYPE
	    BITS=${BASH_REMATCH[5]}
	    # echo $BITS
	else
	    echo "No match for $targ. Exiting."
	    exit
	fi

    # define build architecture
    BUILD_ARCH=$ARCH
    # define whether this is mingw32 or mingw64
    if [[ $BUILD_ARCH == 'i686' ]]; then
        MINGW_DIR_32OR64="mingw32"
    elif [[ $BUILD_ARCH == "x86_64" ]]; then
        MINGW_DIR_32OR64="mingw64"
    fi
    # define build triplet, note the last part of the triplet is always mingw32 even though 64-bit gcc paths can contain mingw64 dirs
    BUILD_TRIPLET=${BUILD_ARCH}-w64-mingw32

    # define gcc thread and exception architecture
    GCC_THREAD_EXCEPT_OSTYPE=$THREAD-$EXCEPT-$OSTYPE
    GCC_THREAD_EXCEPT_OSTYPE_DIR=${GCC_THREAD_EXCEPT_OSTYPE//-/_}

    # define paths
    GCC_PATH=/home/arkay7777/mingw-gcc-${GCC_VER}/${BUILD_ARCH}-${GCC_VER_CODE}-${GCC_THREAD_EXCEPT_OSTYPE}-rt_${MINGW64_CRT}-rev${REV}/${MINGW_DIR_32OR64}
    [[ -d  $GCC_PATH/bin ]] || die "$GCC_PATH does not exist. Exiting."
    export PATH=$GCC_PATH/bin:$SYSPATH
    # CXXFLAGS
    # export CXXFLAGS="-std=c++11 -O2 -m${BITS}"
    export CXXFLAGS="-O2 -m${BITS}"

    # create a fresh (e.g. when recompiling) install directory
    LIBICU_DIR=/c/OSRC/libicu-${ICU_VER_CODE}/libicu_${ICU_VER_CODE}_gcc${GCC_VER_CODE}_${BUILD_ARCH}_${GCC_THREAD_EXCEPT_OSTYPE_DIR}_x${BITS}_rev${REV}
    [[ -e $LIBICU_DIR ]] && rm -rf $LIBICU_DIR
    mkdir $LIBICU_DIR || die "Cannot mkdir ${LIBICU_DIR}"

    # set up the build log and record variables
    LIBICU_BUILD_LOG=${LIBICU_DIR}/build.log
    echo $PATH > ${LIBICU_BUILD_LOG}
    echo $CPATH >> ${LIBICU_BUILD_LOG}
    echo $CXXFLAGS >> ${LIBICU_BUILD_LOG}
    gcc -v 1>>${LIBICU_BUILD_LOG} 2>>${LIBICU_BUILD_LOG}

    # configure and build
    echo "Starting ICU4C build for gcc${GCC_VER_CODE}_${BUILD_ARCH}_${GCC_THREAD_EXCEPT_OSTYPE_DIR}_x${BITS}."
    cd /c/OSRC/libicu-${ICU_VER_CODE}/icu/source || die "Cannot cd to icu/source"
    echo "Configuring..."
    # ./configure --prefix=$LIBICU_DIR --build=${BUILD_TRIPLET} --host=${BUILD_TRIPLET} --enable-static --disable-shared --disable-tools --disable-extras 1>>${LIBICU_BUILD_LOG}
    # ./configure --prefix=$LIBICU_DIR --build=${BUILD_TRIPLET} --host=${BUILD_TRIPLET} --enable-static --disable-shared --disable-tools 1>>${LIBICU_BUILD_LOG}
    # ./configure --prefix=$LIBICU_DIR --build=${BUILD_TRIPLET} --host=${BUILD_TRIPLET} --enable-static --disable-shared --with-data-packaging=static --disable-tools 1>>${LIBICU_BUILD_LOG}
    ./configure --prefix=$LIBICU_DIR --build=${BUILD_TRIPLET} --host=${BUILD_TRIPLET} --enable-static --disable-shared --with-data-packaging=static 1>>${LIBICU_BUILD_LOG}
    cp /c/OSRC/libicu-${ICU_VER_CODE}/icu/source/config.log $LIBICU_DIR
    echo "Building..."
    make -j 4 1>>${LIBICU_BUILD_LOG} 2>>${LIBICU_BUILD_LOG}
    echo "Installing..."
    make -j 4 install 1>>${LIBICU_BUILD_LOG} 2>>${LIBICU_BUILD_LOG}
    echo "Cleaning..."
    make -j 4 clean 1>>${LIBICU_BUILD_LOG} 2>>${LIBICU_BUILD_LOG}

    # check if the include directories are the same for the 32- and 64-bit builds for i686 multilib builds
    if [[ $BUILD_ARCH == "i686" ]] && [[ $BITS == "64" ]]; then
        DIRx64=${LIBICU_DIR}
        DIRx32=${DIRx64/x64/x32}
        DIFF_FILE=/c/OSRC/libicu-${ICU_VER_CODE}/icu/libicu_${ICU_VER_CODE}_gcc${GCC_VER_CODE}_${THREAD}_${EXCEPT}_${OSTYPE}.diff
        diff -ur $DIRx32/include $DIRx64/include > $DIFF_FILE
        [ `ls -l $DIFF_FILE | awk '{print $5}'` -ne 0 ] && die "**Check $DIFF_FILE for diferences in the include directories!**"
    fi


    # install the just-built icu include and lib dirs to the $GCC_PATH/opt
    echo "Installing to ${GCC_PATH}/opt."
    cd ${LIBICU_DIR}
    cp -rpT include $GCC_PATH/opt/include/icu-${ICU_VER_CODE}/
    if ([[ $BUILD_ARCH == "i686" ]] && [[ $BITS == "32" ]]) || [[ $BUILD_ARCH == "x86_64" ]]; then
        cp -rpT lib $GCC_PATH/opt/lib/icu-${ICU_VER_CODE}/
    elif [[ $BUILD_ARCH == "i686" ]] && [[ $BITS == "64" ]]; then
        cp -rpT lib $GCC_PATH/opt/lib/icu-${ICU_VER_CODE}/lib64
    fi

    # add information to buildinfo.txt
    echo "Writing build info to ${GCC_PATH}/build-info.txt"
    echo "name         : icu-${ICU_VER}"                                                                                             >> $GCC_PATH/build-info.txt
    echo "type         : .7z"                                                                                                        >> $GCC_PATH/build-info.txt
    echo "version      : $ICU_VER"                                                                                                   >> $GCC_PATH/build-info.txt
    echo "url          : https://github.com/unicode-org/icu/releases/download/release-${ICU_VER_URL}/icu4c-${ICU_VER_CODE}-src.zip"  >> $GCC_PATH/build-info.txt
    echo "patches      : libicu-config.patch"                                                                                        >> $GCC_PATH/build-info.txt
    if [[ $THREAD == "posix" ]]; then
        echo "configuration: libicu build install v3.sh, <thread> from pthreads"                                                     >> $GCC_PATH/build-info.txt
    elif [[ $THREAD == "win32" ]]; then
        echo "configuration: libicu build install v3.sh, <thread> from github.com/Jamaika1/mingw-std-threads"                        >> $GCC_PATH/build-info.txt
    fi
    echo                                                                                                                             >> $GCC_PATH/build-info.txt
    echo "# **************************************************************************"                                              >> $GCC_PATH/build-info.txt
    echo                                                                                                                             >> $GCC_PATH/build-info.txt

    echo '------------------------------'

done

echo "Done building. Build took $(($SECONDS - STARTTIME)) seconds"


