# **************************************************************************
# set up

# declare variables
GCC_VER="10.1.0"
GCC_VER_CODE=${GCC_VER//./}
MINGW_CRT="v7"
REV="rev0"
BOOST_VER="1_73_0"
BOOST_VER_DOT=${BOOST_VER//_/.}
BOOST_VER_SHORT=$( echo $BOOST_VER | sed -e "s/_[0-9]$//" )

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

# download the boost library if it is not present
cd /c/Users/arkay7777/Desktop/
[[ -e boost_$BOOST_VER.7z ]] || wget https://dl.bintray.com/boostorg/release/$BOOST_VER_DOT/source/boost_$BOOST_VER.7z
# unzip the library to C:/Software/boost-build/ if it is not present and cd
[[ -d /c/Software/boost-build/boost_$BOOST_VER ]] || 7z x -o/c/Software/boost-build/ boost_$BOOST_VER.7z
cd /c/Software/boost-build/boost_$BOOST_VER

# **************************************************************************
# i686 builds

# define build architecture
BUILD_ARCH="i686"

# **************************************************************************
# build and install boost for i686-posix-sjlj

# add posix-sjlj gcc to the $PATH
GCC_PATH=/home/arkay7777/mingw-gcc-${GCC_VER}/${BUILD_ARCH}-${GCC_VER_CODE}-posix-sjlj-rt_${MINGW_CRT}-${REV}/mingw32
[[ -d  $GCC_PATH/bin ]] || die "$GCC_PATH does not exist. Exiting."
export PATH=$GCC_PATH/bin:/usr/local/bin:/usr/bin:/bin:/opt/bin:/c/Windows/System32:/c/Windows:/c/Windows/System32/Wbem:/c/Windows/System32/WindowsPowerShell/v1.0/:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl
# empty CPATH since we have pthreads
export CPATH=""

# specify boost directory. note the need to use "${BOOST_VER}" and "${GCC_VER_CODE}" since they are surrounded by underscores which
# are interpreted literally and so bash expects a variable called "$BOOST_VER_gcc"
BOOST_DIR=C:/Software/boost/boost_${BOOST_VER}_gcc${GCC_VER_CODE}_posix_sjlj
mkdir $BOOST_DIR

# set up the build log and record variables
BOOST_BUILD_LOG=${BOOST_DIR}/build.log
echo $PATH > ${BOOST_BUILD_LOG}
echo $CPATH >> ${BOOST_BUILD_LOG}
gcc -v 1>>${BOOST_BUILD_LOG} 2>>${BOOST_BUILD_LOG}

# build b2.exe with --with-python-root and --with-python specified or else b2.exe will confuse between the Anaconda3 python and the mingw-w64 python.
echo "Running boost bootstrap.sh for ${BUILD_ARCH}-posix-sjlj"
./bootstrap.sh --prefix="$BOOST_DIR" --with-python-root="C:/Software/Anaconda3" --with-python="C:/Software/Anaconda3/python.exe" 1>>${BOOST_BUILD_LOG}
# test if b2.exe was created
[[ -e b2.exe ]] || die "b2.exe was not created. Exiting."
# build boost for i686-posix-sjlj
echo "Running boost b2.exe for ${BUILD_ARCH}-posix-sjlj"
./b2 -a -q cxxflags=-std=c++17 link=static variant=release threading=multi install --without-mpi --without-graph_parallel 1>>${BOOST_BUILD_LOG}
# test if boost was built to the right directory specified in bootstrap.sh above
[[ -d ${BOOST_DIR} ]] || die "${BOOST_DIR} was not compiled correctly."
# and clean up
echo "Cleaning up boost build."
./b2.exe --clean 1>>${BOOST_BUILD_LOG}
export CPATH=""

# install boost into $GCC_PATH
echo "Installing boost-${BOOST_VER} in ${BUILD_ARCH}-posix-sjlj"
cp -rp ${BOOST_DIR}/include/boost* ${GCC_PATH}/opt/include/
cp -rp ${BOOST_DIR}/lib/ ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT}
rm -r ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT}/cmake/

# add information to buildinfo.txt
echo "Writing build info to ${GCC_PATH}/build-info.txt"
echo "name         : boost-${BOOST_VER}"                                                >> $GCC_PATH/build-info.txt
echo "type         : .7z"                                                               >> $GCC_PATH/build-info.txt
echo "version      : $BOOST_VER"                                                        >> $GCC_PATH/build-info.txt
echo "url          : https://dl.bintray.com/boostorg/release/${BOOST_VER_DOT}/source/"  >> $GCC_PATH/build-info.txt
echo "patches      :"                                                                   >> $GCC_PATH/build-info.txt
echo "configuration: boost build.sh, <thread> from pthreads"                            >> $GCC_PATH/build-info.txt
echo                                                                                    >> $GCC_PATH/build-info.txt
echo "# **************************************************************************"     >> $GCC_PATH/build-info.txt
echo                                                                                    >> $GCC_PATH/build-info.txt

# **************************************************************************
# build and install boost for i686-win32-sjlj

# add win32-sjlj gcc to the $PATH
GCC_PATH=/home/arkay7777/mingw-gcc-${GCC_VER}/${BUILD_ARCH}-${GCC_VER_CODE}-win32-sjlj-rt_${MINGW_CRT}-${REV}/mingw32
[[ -d  $GCC_PATH/bin ]] || die "$GCC_PATH does not exist. Exiting."
export PATH=$GCC_PATH/bin:/usr/local/bin:/usr/bin:/bin:/opt/bin:/c/Windows/System32:/c/Windows:/c/Windows/System32/Wbem:/c/Windows/System32/WindowsPowerShell/v1.0/:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl
# add mingw-std-threads to CPATH or else ./bootstrap.sh will fail as it has no knowledge of mingw-std-threads
export CPATH=$GCC_PATH/opt/include/mingw-std-threads

# specify boost directory. note the need to use "${BOOST_VER}" and "${GCC_VER_CODE}" since they are surrounded by underscores which
# are interpreted literally and so bash expects a variable called "$BOOST_VER_gcc"
BOOST_DIR=C:/Software/boost/boost_${BOOST_VER}_gcc${GCC_VER_CODE}_win32_sjlj
mkdir $BOOST_DIR

# set up the build log and record variables
BOOST_BUILD_LOG=${BOOST_DIR}/build.log
echo $PATH > ${BOOST_BUILD_LOG}
echo $CPATH >> ${BOOST_BUILD_LOG}
gcc -v 1>>${BOOST_BUILD_LOG} 2>>${BOOST_BUILD_LOG}

# build b2.exe with --with-python-root and --with-python specified or else b2.exe will confuse between the Anaconda3 python and the mingw-w64 python.
echo "Running boost bootstrap.sh for ${BUILD_ARCH}-win32-sjlj"
./bootstrap.sh --prefix="$BOOST_DIR" --with-python-root="C:/Software/Anaconda3" --with-python="C:/Software/Anaconda3/python.exe" 1>>${BOOST_BUILD_LOG}
# test if b2.exe was created
[[ -e b2.exe ]] || die "b2.exe was not created. Exiting."
# build boost for i686-win32-sjlj
echo "Running boost b2.exe for ${BUILD_ARCH}-win32-sjlj"
./b2 -a -q cflags=-I${GCC_PATH}/opt/include/mingw-std-threads/ cxxflags=-std=c++17 link=static variant=release threading=multi install --without-mpi --without-graph_parallel 1>>${BOOST_BUILD_LOG}
# test if boost was built to the right directory specified in bootstrap.sh above
[[ -d ${BOOST_DIR} ]] || die "${BOOST_DIR} was not compiled correctly."
# and clean up including resetting CPATH
echo "Cleaning up boost build."
./b2.exe --clean 1>>${BOOST_BUILD_LOG}
export CPATH=""

# install boost into $GCC_PATH
echo "Installing boost-${BOOST_VER} in ${BUILD_ARCH}-win32-sjlj"
cp -rp ${BOOST_DIR}/include/boost* ${GCC_PATH}/opt/include/
cp -rp ${BOOST_DIR}/lib/ ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT}
rm -r ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT}/cmake/

# add information to buildinfo.txt
echo "Writing build info to ${GCC_PATH}/build-info.txt"
echo "name         : boost-${BOOST_VER}"                                                >> $GCC_PATH/build-info.txt
echo "type         : .7z"                                                               >> $GCC_PATH/build-info.txt
echo "version      : $BOOST_VER"                                                        >> $GCC_PATH/build-info.txt
echo "url          : https://dl.bintray.com/boostorg/release/${BOOST_VER_DOT}/source/"  >> $GCC_PATH/build-info.txt
echo "patches      :"                                                                   >> $GCC_PATH/build-info.txt
echo "configuration: boost build.sh, <thread> from mingw-std-threads"                   >> $GCC_PATH/build-info.txt
echo                                                                                    >> $GCC_PATH/build-info.txt
echo "# **************************************************************************"     >> $GCC_PATH/build-info.txt
echo                                                                                    >> $GCC_PATH/build-info.txt

# **************************************************************************
# x86_64 builds

# define build architecture
BUILD_ARCH="x86_64"

# **************************************************************************
# build and install boost for i686-posix-seh

# add posix-seh gcc to the $PATH
GCC_PATH=/home/arkay7777/mingw-gcc-${GCC_VER}/${BUILD_ARCH}-${GCC_VER_CODE}-posix-seh-rt_${MINGW_CRT}-${REV}/mingw64
[[ -d  $GCC_PATH/bin ]] || die "$GCC_PATH does not exist. Exiting."
export PATH=$GCC_PATH/bin:/usr/local/bin:/usr/bin:/bin:/opt/bin:/c/Windows/System32:/c/Windows:/c/Windows/System32/Wbem:/c/Windows/System32/WindowsPowerShell/v1.0/:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl
# empty CPATH since we have pthreads
export CPATH=""

# specify boost directory. note the need to use "${BOOST_VER}" and "${GCC_VER_CODE}" since they are surrounded by underscores which
# are interpreted literally and so bash expects a variable called "$BOOST_VER_gcc"
BOOST_DIR=C:/Software/boost/boost_${BOOST_VER}_gcc${GCC_VER_CODE}_posix_seh
mkdir $BOOST_DIR

# set up the build log and record variables
BOOST_BUILD_LOG=${BOOST_DIR}/build.log
echo $PATH > ${BOOST_BUILD_LOG}
echo $CPATH >> ${BOOST_BUILD_LOG}
gcc -v 1>>${BOOST_BUILD_LOG} 2>>${BOOST_BUILD_LOG}

# build b2.exe with --with-python-root and --with-python specified or else b2.exe will confuse between the Anaconda3 python and the mingw-w64 python.
echo "Running boost bootstrap.sh for ${BUILD_ARCH}-posix-seh"
./bootstrap.sh --prefix="$BOOST_DIR" --with-python-root="C:/Software/Anaconda3" --with-python="C:/Software/Anaconda3/python.exe" 1>>${BOOST_BUILD_LOG}
# test if b2.exe was created
[[ -e b2.exe ]] || die "b2.exe was not created. Exiting."
# build boost for x86_64-posix-seh
echo "Running boost b2.exe for ${BUILD_ARCH}-posix-seh"
./b2 -a -q cxxflags=-std=c++17 link=static variant=release threading=multi install --without-mpi --without-graph_parallel 1>>${BOOST_BUILD_LOG}
# test if boost was built to the right directory specified in bootstrap.sh above
[[ -d ${BOOST_DIR} ]] || die "${BOOST_DIR} was not compiled correctly."
# and clean up
echo "Cleaning up boost build."
./b2.exe --clean 1>>${BOOST_BUILD_LOG}
export CPATH=""

# install boost into $GCC_PATH
echo "Installing boost-${BOOST_VER} in ${BUILD_ARCH}-posix-seh"
cp -rp ${BOOST_DIR}/include/boost* ${GCC_PATH}/opt/include/
cp -rp ${BOOST_DIR}/lib/ ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT}
rm -r ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT}/cmake/

# add information to buildinfo.txt
echo "Writing build info to ${GCC_PATH}/build-info.txt"
echo "name         : boost-${BOOST_VER}"                                                >> $GCC_PATH/build-info.txt
echo "type         : .7z"                                                               >> $GCC_PATH/build-info.txt
echo "version      : $BOOST_VER"                                                        >> $GCC_PATH/build-info.txt
echo "url          : https://dl.bintray.com/boostorg/release/${BOOST_VER_DOT}/source/"  >> $GCC_PATH/build-info.txt
echo "patches      :"                                                                   >> $GCC_PATH/build-info.txt
echo "configuration: boost build.sh, <thread> from pthreads"                            >> $GCC_PATH/build-info.txt
echo                                                                                    >> $GCC_PATH/build-info.txt
echo "# **************************************************************************"     >> $GCC_PATH/build-info.txt
echo                                                                                    >> $GCC_PATH/build-info.txt

# **************************************************************************
# build and install boost for i686-win32-seh

# add win32-seh gcc to the $PATH
GCC_PATH=/home/arkay7777/mingw-gcc-${GCC_VER}/${BUILD_ARCH}-${GCC_VER_CODE}-win32-seh-rt_${MINGW_CRT}-${REV}/mingw64
[[ -d  $GCC_PATH/bin ]] || die "$GCC_PATH does not exist. Exiting."
export PATH=$GCC_PATH/bin:/usr/local/bin:/usr/bin:/bin:/opt/bin:/c/Windows/System32:/c/Windows:/c/Windows/System32/Wbem:/c/Windows/System32/WindowsPowerShell/v1.0/:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl
# add mingw-std-threads to CPATH or else ./bootstrap.sh will fail as it has no knowledge of mingw-std-threads
export CPATH=$GCC_PATH/opt/include/mingw-std-threads

# specify boost directory. note the need to use "${BOOST_VER}" and "${GCC_VER_CODE}" since they are surrounded by underscores which
# are interpreted literally and so bash expects a variable called "$BOOST_VER_gcc"
BOOST_DIR=C:/Software/boost/boost_${BOOST_VER}_gcc${GCC_VER_CODE}_win32_seh
mkdir $BOOST_DIR

# set up the build log and record variables
BOOST_BUILD_LOG=${BOOST_DIR}/build.log
echo $PATH > ${BOOST_BUILD_LOG}
echo $CPATH >> ${BOOST_BUILD_LOG}
gcc -v 1>>${BOOST_BUILD_LOG} 2>>${BOOST_BUILD_LOG}

# build b2.exe with --with-python-root and --with-python specified or else b2.exe will confuse between the Anaconda3 python and the mingw-w64 python.
echo "Running boost bootstrap.sh for ${BUILD_ARCH}-win32-seh"
./bootstrap.sh --prefix="$BOOST_DIR" --with-python-root="C:/Software/Anaconda3" --with-python="C:/Software/Anaconda3/python.exe" 1>>${BOOST_BUILD_LOG}
# test if b2.exe was created
[[ -e b2.exe ]] || die "b2.exe was not created. Exiting."
# build boost for x86_64-win32-seh
echo "Running boost b2.exe for ${BUILD_ARCH}-win32-seh"
./b2 -a -q cflags=-I${GCC_PATH}/opt/include/mingw-std-threads/ cxxflags=-std=c++17 link=static variant=release threading=multi install --without-mpi --without-graph_parallel 1>>${BOOST_BUILD_LOG}
# test if boost was built to the right directory specified in bootstrap.sh above
[[ -d ${BOOST_DIR} ]] || die "${BOOST_DIR} was not compiled correctly."
# and clean up including resetting CPATH
echo "Cleaning up boost build."
./b2.exe --clean 1>>${BOOST_BUILD_LOG}
CPATH=""

# install boost into $GCC_PATH
echo "Installing boost-${BOOST_VER} in ${BUILD_ARCH}-win32-seh"
cp -rp ${BOOST_DIR}/include/boost* ${GCC_PATH}/opt/include/
cp -rp ${BOOST_DIR}/lib/ ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT}
rm -r ${GCC_PATH}/opt/lib/boost-${BOOST_VER_SHORT}/cmake/

# add information to buildinfo.txt
echo "Writing build info to ${GCC_PATH}/build-info.txt"
echo "name         : boost-${BOOST_VER}"                                                >> $GCC_PATH/build-info.txt
echo "type         : .7z"                                                               >> $GCC_PATH/build-info.txt
echo "version      : $BOOST_VER"                                                        >> $GCC_PATH/build-info.txt
echo "url          : https://dl.bintray.com/boostorg/release/${BOOST_VER_DOT}/source/"  >> $GCC_PATH/build-info.txt
echo "patches      :"                                                                   >> $GCC_PATH/build-info.txt
echo "configuration: boost build.sh, <thread> from mingw-std-threads"                   >> $GCC_PATH/build-info.txt
echo                                                                                    >> $GCC_PATH/build-info.txt
echo "# **************************************************************************"     >> $GCC_PATH/build-info.txt
echo                                                                                    >> $GCC_PATH/build-info.txt


