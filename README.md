# myGCCBuilds
my gcc builds based on mingw-builds.

These personal builds are based on the develop branch scripts from [mingw-builds](https://github.com/niXman/mingw-builds/tree/develop).

I have added bash shell scripts and patches in the repository in case you would like to attempt a build on your own. Start with [gcc mingw-w64 build v2.sh](https://github.com/MNRK01/myGCCBuilds/blob/78f2ed70e71b7f50e89bb407fefa8a0a95f78f52/gcc%20mingw-w64%20build%20v2.sh) or a newer version of the same. You will need a functioning 64-bit [msys2](https://www.msys2.org/) environment via ```pacman -S base-devel vim subversion zip unzip p7zip sshpass dejagnu git perl``` to be able to use the scripts in this repo. 

For gcc itself, I have a minimal patch to:

1) Change the MINGW_W64_PKG_STRING string to reflect that I am building the packages

For the Win32 builds, I am including [mingw-std-threads](https://github.com/Jamaika1/mingw_std_threads) to provide C++11 functionality such as ```<thread>```, ```<mutex>``` and others as they are not available in non-posix (i.e. non-pthreads based) builds.

These personal builds are made available as a community service.

