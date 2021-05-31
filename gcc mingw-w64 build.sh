#################################################
# set up
pacman -Syuu
export HOME=/home/arkay7777/
cd
rm -rf mingw-gcc-10.2.0/
rm -rf mingw-builds/
cd && git clone --branch develop https://github.com/niXman/mingw-builds.git
# should fail and echo "no /mingw"
cd /mingw 1>/dev/null 2>&1 || ( [[ `echo $?` != 0 ]]  && echo "No /mingw directory found (good)." )
cd && patch -uN -p 1 --binary --dry-run --verbose -d mingw-builds/ < '/c/Users/arkay7777/Documents/gcc mingw-builds v1.patch'
cd && patch -uN -p 1 --binary --verbose -d mingw-builds/ < '/c/Users/arkay7777/Documents/gcc mingw-builds v1.patch'
# there should be no gcc on $PATH
echo $PATH
# should fail and echo "no gcc"
gcc -v 1>/dev/null 2>&1 || ( [[ `echo $?` != 0 ]]  && echo "No gcc on the path (good)." )
#################################################
# start gcc build, the 2nd i686 or x86_64 build does not need to rebuild the gcc dependencies
# edit gcc and mingw-w64 rt-versions
cd && cd mingw-builds
./build --help
./build --mode=gcc-10.3.0 --arch=i686 --threads=posix --exceptions=sjlj --enable-languages=c,c++,fortran --rt-version=v8 --jobs=4 --rev=0
./build --mode=gcc-10.3.0 --arch=i686 --threads=win32 --exceptions=sjlj --enable-languages=c,c++,fortran --rt-version=v8 --jobs=4 --rev=0
./build --mode=gcc-10.3.0 --arch=x86_64 --threads=posix --exceptions=seh --enable-languages=c,c++,fortran --rt-version=v8 --jobs=4 --rev=0
./build --mode=gcc-10.3.0 --arch=x86_64 --threads=win32 --exceptions=seh --enable-languages=c,c++,fortran --rt-version=v8 --jobs=4 --rev=0
#################################################
# mingw-std-threads build and install
/c/Users/arkay7777/Documents/mingw-std-threads\ install\ v3.sh
#################################################
# libicu, boost and gsl build and install, update each script to the library, gcc and mingw-w64 crt versions
/c/Users/arkay7777/Documents/libicu\ build\ install\ v2.sh
/c/Users/arkay7777/Documents/boost\ build\ install\ v2.sh
/c/Users/arkay7777/Documents/gsl\ build.sh


