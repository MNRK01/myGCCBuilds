# this script builds boost libraries and installs them into a mingw-w64 toolset
# Boost.Build (b2) Reference: https://boostorg.github.io/build/manual/develop/
# **************************************************************************
# set up

STARTTIME=$SECONDS

# declare variables
GCC_VER="11.1.0"
GCC_VER_CODE=${GCC_VER//./}
MINGW_CRT="v9"
REV="rev0"
BOOST_VER="1_76_0"
BOOST_VER_DOT=${BOOST_VER//_/.}
BOOST_VER_SHORT=$( echo $BOOST_VER | sed -e "s/_[0-9]$//" )
ICU_VER="69.1"
ICU_VER_CODE=${ICU_VER/./_}

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

# download the boost library if the target boost directory it is not present
# unzip the library to C:/OSRC/boost/ if it is not present and cd
cd /c/Users/arkay7777/Desktop/
if [[ ! -d /c/OSRC/boost/boost_$BOOST_VER ]]; then
    [[ -e boost_$BOOST_VER.7z ]] || wget https://dl.bintray.com/boostorg/release/$BOOST_VER_DOT/source/boost_$BOOST_VER.7z;
    7z x -o/c/OSRC/boost/ boost_$BOOST_VER.7z;
fi
echo "---------------------------------"

# rest of the build occurs in boost_$BOOST_VER directory
cd /c/OSRC/boost/boost_$BOOST_VER

# apply patches to make the compilation under win32 thread model work - these builds do not support threading out of the box
PATCHLOG=/c/OSRC/boost/boost_$BOOST_VER/patch.log
echo "Patching gcc.hpp and libstdcpp3.hpp"
PATCH_OUT=$(patch --verbose -uN -r /dev/null ./boost/config/compiler/gcc.hpp < /c/Users/arkay7777/Documents/boost\ build\ gcc.hpp.patch)
# need to quote to output newlines, https://stackoverflow.com/questions/613572/capturing-multiple-line-output-into-a-bash-variable
if [ $? == 0 ]; then
    echo "$PATCH_OUT" > ${PATCHLOG}
    echo "$PATCH_OUT"
elif [[ $PATCH_OUT =~ 'Reversed (or previously applied) patch detected!' ]]; then
    echo "$PATCH_OUT" > ${PATCHLOG}
    echo "$PATCH_OUT"
    echo "\"boost build gcc.hpp.patch\" has been previously applied. Patch skipped."
else
    die "\"boost build gcc.hpp.patch\" failed. Exiting."
fi
PATCH_OUT=$(patch --verbose -uN -r /dev/null ./boost/config/stdlib/libstdcpp3.hpp < /c/Users/arkay7777/Documents/boost\ build\ libstdcpp3.hpp\ v2.patch)
if [ $? == 0 ]; then
    echo "$PATCH_OUT" >> ${PATCHLOG}
    echo "$PATCH_OUT"
elif [[ $PATCH_OUT =~ 'Reversed (or previously applied) patch detected!' ]]; then
    echo "$PATCH_OUT" > ${PATCHLOG}
    echo "$PATCH_OUT"
    echo "\"boost build libstdcpp3.hpp v2.patch\" has been previously applied. Patch skipped."
else
    die "\"boost build libstdcpp3.hpp v2.patch\" failed. Exiting."
fi
echo "---------------------------------"

# define paths
SYSPATH=$PATH
PYPATH=/c/OSRC/Anaconda3:/c/OSRC/Anaconda3/Library/mingw-w64/bin:/c/OSRC/Anaconda3/Library/usr/bin:/c/OSRC/Anaconda3/Library/bin:/c/OSRC/Anaconda3/Scripts:/c/OSRC/Anaconda3/bin:/c/OSRC/Anaconda3/condabin

# define targets to make
ALLTARGS=(
	          "i686-posix-sjlj-x32"
	          "i686-posix-sjlj-x64"
	          "i686-win32-sjlj-x32"
	          "i686-win32-sjlj-x64"
	          "x86_64-posix-seh-x64"
	          "x86_64-win32-seh-x64"
	     )

# loop through ALLTARGS and build and install libicu
for targ in "${ALLTARGS[@]}"
do
	echo "Building for $targ"
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
    GCC_THREAD_EXCEPT=$THREAD-$EXCEPT
    GCC_THREAD_EXCEPT_DIR=${GCC_THREAD_EXCEPT/-/_}

    # define paths
    GCC_PATH=/c/OSRC/gcc-build/msys64/home/arkay7777/mingw-gcc-${GCC_VER}/${BUILD_ARCH}-${GCC_VER_CODE}-${GCC_THREAD_EXCEPT}-rt_${MINGW_CRT}-${REV}/${MINGW_DIR_32OR64}
    echo $GCC_PATH
    [[ -d  $GCC_PATH/bin ]] || die "$GCC_PATH does not exist. Exiting."
    export PATH=$GCC_PATH/bin:$PYPATH:$SYSPATH
    # $MINGWSTDTHREADSDIR is defined if $THREAD is win32
    if [[ $THREAD == "posix" ]]; then
        # $MINGWSTDTHREADSDIR is empty
        MINGWSTDTHREADSDIR=""
    elif [[ $THREAD == "win32" ]]; then
        # $MINGWSTDTHREADSDIR is set to opt/include/mingw-std-threads
        [[ -e ${GCC_PATH}/opt/include/mingw-std-threads ]] || die "No mingw-std-threads"
        # use /usr/bin/cygpath.exe rather than the one found in /c/OSRC/Anaconda3/Library/usr/bin!
        MINGWSTDTHREADSDIR=$(/usr/bin/cygpath.exe -m ${GCC_PATH}/opt/include/mingw-std-threads)
    fi
    echo $MINGWSTDTHREADSDIR
    # add mingw-std-threads to CPATH if $THREAD == "win32"
    export CPATH=$MINGWSTDTHREADSDIR

    # path to ICU, include directory is the same for all icu builds
    [[ -e ${GCC_PATH}/opt/include/icu-${ICU_VER_CODE} ]] || die "No libicu include directory"
    # use /usr/bin/cygpath.exe rather than the one found in /c/OSRC/Anaconda3/Library/usr/bin!
    ICU_INC_DIR=$(/usr/bin/cygpath.exe -m $GCC_PATH/opt/include/icu-${ICU_VER_CODE})
    echo $ICU_INC_DIR
    # lib directory is the same for i686, x32 or x86_64 builds
    if ([[ $BUILD_ARCH == "i686" ]] && [[ $BITS == "32" ]]) || [[ $BUILD_ARCH == "x86_64" ]]; then
        [[ -e ${GCC_PATH}/opt/lib/icu-${ICU_VER_CODE} ]] || die "No libicu lib directory"
        # use /usr/bin/cygpath.exe rather than the one found in /c/OSRC/Anaconda3/Library/usr/bin!
        ICU_LIB_DIR=$(/usr/bin/cygpath.exe -m $GCC_PATH/opt/lib/icu-${ICU_VER_CODE})
    # lib directory is different (lib64 sub-directory) specifically for i686, x64 multilib builds
    elif [[ $BUILD_ARCH == "i686" ]] && [[ $BITS == "64" ]]; then
        [[ -e ${GCC_PATH}/opt/lib/icu-${ICU_VER_CODE}/lib64 ]] || die "No libicu lib64 directory"
        # use /usr/bin/cygpath.exe rather than the one found in /c/OSRC/Anaconda3/Library/usr/bin!
        ICU_LIB_DIR=$(/usr/bin/cygpath.exe -m $GCC_PATH/opt/lib/icu-${ICU_VER_CODE}/lib64)
    fi

    # specify boost directory. note the need to use "${BOOST_VER}" and "${GCC_VER_CODE}" since they are surrounded by underscores which
    # are interpreted literally and so bash expects a variable called "$BOOST_VER_gcc"
    BOOST_DIR=C:/OSRC/boost/boost_${BOOST_VER}_gcc${GCC_VER_CODE}_${GCC_THREAD_EXCEPT_DIR}_x${BITS}
    [[ -e $BOOST_DIR ]] && rm -rf $BOOST_DIR
    mkdir $BOOST_DIR || die "Cannot mkdir ${BOOST_DIR}"

    # set up the build log and record variables
    BOOST_BUILD_LOG=${BOOST_DIR}/build.log
    echo $PATH > ${BOOST_BUILD_LOG}
    echo $CPATH >> ${BOOST_BUILD_LOG}
    gcc -v 1>>${BOOST_BUILD_LOG} 2>>${BOOST_BUILD_LOG}

    # create a user-config.jam file with -I"$MINGWSTDTHREADSDIR" if $THREAD == "win32"
    # note the two levels of escapes for the -I"...". the first level of escape is needed for echo to write to user-config.jam.
    # the user-config.jam file should have -I\"...\" written to it. the second level of escape in the user-config.jam file
    # is for when b2.exe reads user-config.jam. without it, the <compileflags> directive will end when the quote in -I"... is
    # reached causing incorrect configuration that is seen in the /c/OSRC/boost/boost_$BOOST_VER/bin.v2/config.log file.
    USER_CONFIG_JAM=/c/OSRC/boost/boost_$BOOST_VER/tools/build/src/user-config.jam
    if [[ $THREAD == "posix" ]]; then
        echo "using gcc : : : <compileflags>\"-DMINGW_HAS_THREADS -DU_STATIC_IMPLEMENTATION -I\\\"$ICU_INC_DIR\\\" \" \
              <linkflags>\"-L\\\"$ICU_LIB_DIR\\\"\" ;" > $USER_CONFIG_JAM
    elif [[ $THREAD == "win32" ]]; then
        echo "using gcc : : : <compileflags>\"-DMINGW_HAS_THREADS -DU_STATIC_IMPLEMENTATION -I\\\"${MINGWSTDTHREADSDIR}\\\" \
             -I\\\"$ICU_INC_DIR\\\" \" <linkflags>\"-L\\\"$ICU_LIB_DIR\\\"\" ;" > $USER_CONFIG_JAM
    fi

    # build b2.exe with --with-python-root and --with-python specified or else b2.exe will confuse between the Anaconda3 python and the mingw-w64 python.
    echo "Running boost bootstrap.sh for ${BUILD_ARCH}-${GCC_THREAD_EXCEPT}-${BITS}bit"
    # ./bootstrap.sh --prefix="$BOOST_DIR" --with-python-root="C:/OSRC/Anaconda3" --with-python="C:/OSRC/Anaconda3/python.exe" --with-icu=${ICU_INC_DIR} 1>>${BOOST_BUILD_LOG}
    ./bootstrap.sh --with-toolset=gcc --prefix="$BOOST_DIR" --with-python-root="C:/OSRC/Anaconda3" --with-python="C:/OSRC/Anaconda3/python.exe" 1>>${BOOST_BUILD_LOG}
    # test if b2.exe was created
    [[ -e b2.exe ]] || die "b2.exe was not created. Exiting."
    # build boost
    echo "Running boost b2.exe for ${BUILD_ARCH}-${GCC_THREAD_EXCEPT}-${BITS}bit"
    # ./b2 -a -q cxxflags="-std=c++17" link=static variant=release threading=multi install --without-mpi --without-graph_parallel 1>>${BOOST_BUILD_LOG}
    # ./b2 -a -q cflags="-I${ICU_INC_DIR} -DU_STATIC_IMPLEMENTATION" cxxflags="-std=c++17" linkflags="-L${ICU_LIB_DIR}" link=static variant=release threading=multi install --without-mpi --without-graph_parallel 1>>${BOOST_BUILD_LOG}
    ./b2 -a -q -j 4 --debug-configuration toolset=gcc address-model=$BITS link=static variant=release threading=multi install --without-mpi --without-graph_parallel 1>>${BOOST_BUILD_LOG}
    # test if boost was built to the right directory specified in bootstrap.sh above
    [[ -d ${BOOST_DIR} ]] || die "${BOOST_DIR} was not compiled correctly."
    # and clean up
    echo "Cleaning up boost build."
    ./b2.exe --clean 1>>${BOOST_BUILD_LOG}
    export CPATH=""

    # check if the include directories are the same for the 32- and 64-bit builds
    if [[ $BUILD_ARCH == "i686" ]] && [[ $BITS == "64" ]]; then
        DIRx64=${BOOST_DIR}
        DIRx32=${DIRx64/x64/x32}
        DIFF_FILE=./boost_${BOOST_VER}_gcc${GCC_VER_CODE}_${GCC_THREAD_EXCEPT_DIR}.diff
        diff -ur ${DIRx32}/include ${DIRx64}/include > $DIFF_FILE
        [ `ls -l $DIFF_FILE | awk '{print $5}'` -ne 0 ] && die "**Check $DIFF_FILE for diferences in the include directories!**"
    fi

    # copy config.log into $BOOST_DIR
    cp C:/OSRC/boost/boost_${BOOST_VER}/bin.v2/config.log $BOOST_DIR

    # install boost into $GCC_PATH
    echo "Installing boost-${BOOST_VER}-${BITS}bit in ${BUILD_ARCH}-${GCC_THREAD_EXCEPT}"
    # delete the existing opt/include and opt/lib directories only if we're not installing i686, 64-bit multilib build
    if ([[ $BUILD_ARCH == "i686" ]] && [[ $BITS == "32" ]]) || [[ $BUILD_ARCH == "x86_64" ]]; then
        [[ -d ${GCC_PATH}/opt/include/boost-${BOOST_VER_SHORT} ]] && rm -rf ${GCC_PATH}/opt/include/boost-${BOOST_VER_SHORT}
        [[ -d ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT} ]] && rm -rf ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT}
    fi
    cp -rpT ${BOOST_DIR}/include/boost-$BOOST_VER_SHORT ${GCC_PATH}/opt/include/boost-$BOOST_VER_SHORT
    cp -rpT ${BOOST_DIR}/lib/ ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT}
    [[ -d ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT}/cmake/ ]] && rm -r ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT}/cmake/

    # add information to buildinfo.txt
    echo "Writing build info to ${GCC_PATH}/build-info.txt"
    echo "name         : boost-${BOOST_VER_DOT}"                                                     >> $GCC_PATH/build-info.txt
    echo "type         : .7z"                                                                        >> $GCC_PATH/build-info.txt
    echo "version      : $BOOST_VER_DOT"                                                             >> $GCC_PATH/build-info.txt
    echo "url          : https://dl.bintray.com/boostorg/release/${BOOST_VER_DOT}/source/"           >> $GCC_PATH/build-info.txt
    echo "patches      : gcc.hpp.patch, libstdcpp3.hpp.patch"                                        >> $GCC_PATH/build-info.txt
    if [[ $THREAD == "posix" ]] && [[ $BITS == "32" ]]; then
        echo "configuration: boost build install v2.sh, 32-bit mt, <thread> from pthreads"           >> $GCC_PATH/build-info.txt
    elif [[ $THREAD == "posix" ]] && [[ $BITS == "64" ]]; then
        echo "configuration: boost build install v2.sh, 64-bit mt, <thread> from pthreads"           >> $GCC_PATH/build-info.txt
    elif [[ $THREAD == "win32" ]] && [[ $BITS == "32" ]]; then
        echo "configuration: boost build install v2.sh, 32-bit mt, <thread> from mingw-std-threads"  >> $GCC_PATH/build-info.txt
    elif [[ $THREAD == "win32" ]] && [[ $BITS == "64" ]]; then
        echo "configuration: boost build install v2.sh, 64-bit mt, <thread> from mingw-std-threads"  >> $GCC_PATH/build-info.txt
    fi
    echo                                                                                             >> $GCC_PATH/build-info.txt
    echo "# **************************************************************************"              >> $GCC_PATH/build-info.txt
    echo                                                                                             >> $GCC_PATH/build-info.txt

    echo "---------------------------------"
done

# print the time required for the build in seconds
echo "Done building. Build took $(($SECONDS - STARTTIME)) seconds"


