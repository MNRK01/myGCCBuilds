# myGCCBuilds
my gcc builds based on mingw-builds.

These personal builds are based on the develop branch scripts from [mingw-builds](https://github.com/niXman/mingw-builds/tree/develop). Beginning with gcc 12.3, the x86_64-posix-seh builds use the UCRT C standard library instead of MSVCRT.

I have added bash shell scripts and patches in the repository in case you would like to attempt a build on your own. Start with [gcc mingw-w64 build v2.sh](https://github.com/MNRK01/myGCCBuilds/blob/78f2ed70e71b7f50e89bb407fefa8a0a95f78f52/gcc%20mingw-w64%20build%20v2.sh) or a newer version of the same. You will need a functioning 64-bit [msys2](https://www.msys2.org/) environment via ```pacman -S base-devel vim subversion zip unzip p7zip sshpass dejagnu git perl``` to be able to use the scripts in this repo. 

For gcc itself, I have a minimal patch to:

1) Change the MINGW_W64_PKG_STRING string to reflect that I am building the packages
2) Make sjlj builds multilib

I also provide Boost C++ Libraries and the GNU Scientific Library (GSL) in my recent builds.

When I provided Win32 builds, I used to include [mingw-std-threads](https://github.com/Jamaika1/mingw_std_threads) to provide C++11 functionality such as ```<thread>```, ```<mutex>``` and others as they are not available in non-posix (i.e. non-pthreads based) builds. I am no longer providing these Win32 builds since I can no longer get mingw-std-threads to compile with gcc >= 11.1 due to the structure of mingw-std-threads leading to "previous declaration" errors during compilation with the C++11 threading headers. I have filed a [PR report](https://github.com/meganz/mingw-std-threads/issues/79) with that repository.

These personal builds are made available as a community service.

