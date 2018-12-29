# myGCCBuilds
my gcc builds based on mingw-builds

These builds are based on the develop branch scripts from mingw-builds:

https://github.com/niXman/mingw-builds/tree/develop

I have a text file with my build notes in the repository in case you would like to attempt a build on your own.

I have a minimal patche to:

1) Disable x86_64 version of lto-test since it is failing although the i686 version of the same test is passing.
2) Change the MINGW_W64_PKG_STRING string to reflect that I am building the packages

These builds are made available as a community service.

