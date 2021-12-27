#################################################
# need the following minimal set of programs to run this script:
# bash, pacman, base-devel, msys2-devel, subversion, zip, unzip, p7zip, tar, sshpass, dejagnu, git, wget,
# patch, diff, vim, cygpath, sed, awk, perl, powershell, make, flex, bison, lndir, gettext, texinfo,
# autotools, autogen
#################################################
# set up
pacman -Syuu
export HOME=/home/arkay7777/
cd
rm -rf mingw-gcc-11.1.0/ mingw-builds/
[[ -e mingw-builds-orig/ ]] && rm -rf mingw-builds-orig/
cd && git clone --branch develop https://github.com/niXman/mingw-builds.git
cp -rp mingw-builds/ mingw-builds-orig/
# should fail and echo "no /mingw"
cd /mingw 1>/dev/null 2>&1 || ( [[ `echo $?` != 0 ]]  && echo "No /mingw directory found (good)." )
cd && patch -uN -p 1 --binary --dry-run --verbose -d mingw-builds/ < '/c/Users/arkay7777/Documents/gcc mingw-builds v2.patch'
cd && patch -uN -p 1 --binary --verbose -d mingw-builds/ < '/c/Users/arkay7777/Documents/gcc mingw-builds v2.patch'
# there should be no gcc on $PATH
echo $PATH
# should fail and echo "no gcc"
gcc -v 1>/dev/null 2>&1 || ( [[ `echo $?` != 0 ]]  && echo "No gcc on the path (good)." )
#################################################
# set key environment variables for the commands below
export GCC_VER='11.2.0'
export MINGW64_CRT='v9'
export REV='0'
export ICU_VER='70.1'
export BOOST_VER='1_78_0'
export GSL_VER='2.7'
#################################################
# start gcc build, the 2nd i686 or x86_64 build does not need to rebuild the gcc dependencies
# edit gcc and mingw-w64 rt-versions. turn off computer sleep settings.
cd && cd mingw-builds
./build --help
./build --mode=gcc-$GCC_VER --arch=i686 --threads=posix --exceptions=sjlj --enable-languages=c,c++,fortran --with-default-msvcrt=msvcrt --rt-version=$MINGW64_CRT --jobs=4 --rev=$REV
# ./build --mode=gcc-$GCC_VER --arch=i686 --threads=win32 --exceptions=sjlj --enable-languages=c,c++,fortran --with-default-msvcrt=msvcrt --rt-version=$MINGW64_CRT --jobs=4 --rev=$REV
./build --mode=gcc-$GCC_VER --arch=x86_64 --threads=posix --exceptions=seh --enable-languages=c,c++,fortran --with-default-msvcrt=msvcrt --rt-version=$MINGW64_CRT --jobs=4 --rev=$REV
# ./build --mode=gcc-$GCC_VER --arch=x86_64 --threads=win32 --exceptions=seh --enable-languages=c,c++,fortran --with-default-msvcrt=msvcrt --rt-version=$MINGW64_CRT --jobs=4 --rev=$REV
#################################################
# Jamaika mingw-std-threads build and install - mingw-std-threads and Jamaika/mingw-std-threads are totally broken for GCC >= 11
# /c/Users/arkay7777/Documents/mingw-std-threads\ install\ v4.sh
#################################################
# libicu, boost and gsl build and install for POSIX threading only
/c/Users/arkay7777/Documents/libicu\ build\ install\ v3.sh
/c/Users/arkay7777/Documents/boost\ build\ install\ v3.sh
/c/Users/arkay7777/Documents/gsl\ build\ install.sh


