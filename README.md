# myGCCBuilds
my gcc builds based on mingw-builds

These personal builds are based on the develop branch scripts from mingw-builds:

https://github.com/niXman/mingw-builds/tree/develop

I have added bash shell scripts and patches in the repository in case you would like to attempt a build on your own. You will need a functioning 64-bit [msys2](https://www.msys2.org/) environment via ```pacman -S base-devel vim subversion zip unzip p7zip sshpass dejagnu git perl``` to be able to use the scripts in this repo. 

For gcc itself, I have a minimal patch to:

1) Change the MINGW_W64_PKG_STRING string to reflect that I am building the packages

For the Win32 builds, I am including [mingw-std-threads](https://github.com/Jamaika1/mingw_std_threads) to provide C++11 functionality such as <thread>, <mutex> and others as they are not available in non-posix (pthreads) builds.

These personal builds are made available as a community service.

