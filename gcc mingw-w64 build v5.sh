#################################################
# need the following minimal set of programs to run this script:
# bash, pacman, base-devel, msys2-devel, subversion, zip, unzip, p7zip, tar, sshpass, dejagnu, git, wget,
# patch, diff, vim, cygpath, sed, awk, perl, powershell, make, flex, bison, lndir, gettext, texinfo,
# autotools, autogen, autoconf-archive, basename
#################################################
# set up
pacman -Syuu
export HOME=/home/arkay7777/
cd
rm -rf mingw-gcc-12.2.0/ mingw-builds/
[[ -e mingw-builds-orig/ ]] && rm -rf mingw-builds-orig/
[[ -e /c/OSRC/gcc-build/pybuild ]] && rm -rf /c/OSRC/gcc-build/pybuild
cd && git clone --branch develop https://github.com/niXman/mingw-builds.git
cp -rp mingw-builds/ mingw-builds-orig/
# should fail and echo "no /mingw"
cd /mingw 1>/dev/null 2>&1 || ( [[ `echo $?` != 0 ]]  && echo "No /mingw directory found (good)." )
# apply mingw-builds patches
cd && patch -uN -p 1 --binary --dry-run --verbose -d mingw-builds/ < '/c/Users/arkay7777/Documents/gcc mingw-builds v3.patch'
cd && patch -uN -p 1 --binary --verbose -d mingw-builds/ < '/c/Users/arkay7777/Documents/gcc mingw-builds v3.patch'
# python3 patches. see https://docs.python.org/3/install/ for how python uses distutils and setup.py to build modules
cp -ip '/c/Users/arkay7777/Documents/gcc-python3-configure-script v1.patch' ./mingw-builds/patches/Python3/0200-arkay7777-configure-script.patch
cp -ip '/c/Users/arkay7777/Documents/gcc-python3-distutils-cfg v1.patch' ./mingw-builds/patches/Python3/0300-arkay7777-distutils-cfg.patch
cd && patch -uN --binary --dry-run --verbose -d mingw-builds/scripts/ < '/c/Users/arkay7777/Documents/gcc-python3-build-script v2.patch'
cd && patch -uN --binary --verbose -d mingw-builds/scripts/ < '/c/Users/arkay7777/Documents/gcc-python3-build-script v2.patch'
# gdb patches to prevent missing term.h error
cp -ip /c/Users/arkay7777/Documents/gcc-gdb-curses-h\ v1.patch /c/OSRC/gcc-build/msys64/home/arkay7777/mingw-builds/patches/gdb/900-gdb-curses-h.patch
cd && patch -uN --binary --dry-run --verbose -i /c/Users/arkay7777/Documents/gcc-gdb-build-script\ v1.patch mingw-builds/scripts/gdb.sh
cd && patch -uN --binary --verbose -i /c/Users/arkay7777/Documents/gcc-gdb-build-script\ v1.patch mingw-builds/scripts/gdb.sh
# there should be no gcc on $PATH
echo $PATH
# should fail and echo "no gcc"
gcc -v 1>/dev/null 2>&1 || ( [[ `echo $?` != 0 ]]  && echo "No gcc on the path (good)." )
#################################################
# set key environment variables for the commands below. check `./build --help` below and various websites for latest version info
export GCC_VER='13.1.0'
export MINGW64_CRT='v11'
export BUILD_CRT='msvcrt'
export REV='0'
export ICU_VER='73.2'
export BOOST_VER='1_82_0'
export GSL_VER='2.7'
#################################################
# start gcc build, the 2nd i686 or x86_64 build does not need to rebuild the gcc dependencies
# edit gcc and mingw-w64 rt-versions. turn off computer sleep settings and possibly anti-virus.
cd && cd mingw-builds
./build --help
# ./build --mode=gcc-$GCC_VER --arch=i686 --threads=posix --exceptions=sjlj --enable-languages=c,c++,fortran --with-default-msvcrt=ucrt --rt-version=$MINGW64_CRT --jobs=4 --rev=$REV
# ./build --mode=gcc-$GCC_VER --arch=i686 --threads=posix --exceptions=sjlj --enable-languages=c,c++,fortran --with-default-msvcrt=ucrt --rt-version=$MINGW64_CRT --jobs=4 --rev=$REV --bootstrapall
# temporarily change the toolchain download URL since a recent one for posix-sjlj is not available
patch -uN --binary --dry-run --verbose -p 1 -i /c/Users/arkay7777/Documents/gcc\ config-win-sjlj.patch
patch -uN --binary --verbose -p 1 -i /c/Users/arkay7777/Documents/gcc\ config-win-sjlj.patch
./build --mode=gcc-$GCC_VER --arch=i686 --threads=posix --exceptions=sjlj --enable-languages=c,c++,fortran --with-default-msvcrt=msvcrt --rt-version=$MINGW64_CRT --jobs=4 --rev=$REV
# reverse the patch for the toolchain download URL
patch -uR --binary --dry-run --verbose -p 1 -i /c/Users/arkay7777/Documents/gcc\ config-win-sjlj.patch
patch -uR --binary --verbose -p 1 -i /c/Users/arkay7777/Documents/gcc\ config-win-sjlj.patch
./build --mode=gcc-$GCC_VER --arch=x86_64 --threads=posix --exceptions=seh --enable-languages=c,c++,fortran --with-default-msvcrt=ucrt --rt-version=$MINGW64_CRT --jobs=4 --rev=$REV
#################################################
# libicu, boost and gsl build and install for POSIX threading only
/c/Users/arkay7777/Documents/libicu\ build\ install\ v4.sh
/c/Users/arkay7777/Documents/boost\ build\ install\ v4.sh
/c/Users/arkay7777/Documents/gsl\ build\ install\ v2.sh


