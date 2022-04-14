echo Synchronize and build libbibledit on macOS for macOS.


echo Take the relevant source code for building Bibledit for macOS.
echo Put it in a temporal location.
echo Purpose: Not to have duplicated source code for the bibledit library.
echo This does not clutter the bibledit git repository with the build files.
MACOSSOURCE=`dirname $0`
cd $MACOSSOURCE
if [ $? != 0 ]; then exit; fi
BIBLEDITMACOS=/tmp/bibledit-macos
echo Synchronizing relevant source code to $BIBLEDITMACOS
mkdir -p $BIBLEDITMACOS
rm $BIBLEDITMACOS/* 2> /dev/null
rsync --archive --delete ../cloud $BIBLEDITMACOS/
if [ $? != 0 ]; then exit; fi
rsync --archive --delete ../macos $BIBLEDITMACOS/
if [ $? != 0 ]; then exit; fi


echo From now on the working directory is the temporal location.
cd $BIBLEDITMACOS/macos
if [ $? != 0 ]; then exit; fi


pushd webroot
if [ $? != 0 ]; then exit; fi


echo Synchronize the libbibledit data files in the source tree to macOS.
rsync -a --delete ../../cloud/ .
if [ $? != 0 ]; then exit; fi
echo Dist-clean the Bibledit library.
./configure
if [ $? != 0 ]; then exit; fi
make distclean
if [ $? != 0 ]; then exit; fi
rm config.h


echo Update the Makefile.am and reconfigure
sed -i.bak '/mbedtls_ssl_init/d' configure.ac
./reconfigure


echo Export the Xcode toolchain for C and C++.
# This no longer works.
# It led to errors.
# It appears that the 'which clang' points to the same clang as below.
# So it is no longer needed to set those environment variables.
# export CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
# export CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"


echo The Xcode macOS SDK.
SDK=`xcrun --show-sdk-path`


echo Configure Bibledit in client mode.
./configure --enable-mac
if [ $? != 0 ]; then exit; fi
# No longer set the network port.
# The Bibledit kernel will negotiate its own network port number.
# echo 9876 > config/network-port
# if [ $? != 0 ]; then exit; fi


echo Update the Makefile.
echo The -mmmacosx-version-min is for fixing: ld: warning:
echo object file libbibledit.a was built for newer macOS version than being linked.
echo The added architectures to the CFLAGS are for Apple Silicon.
echo See https://developer.apple.com/forums/thread/653233.
sed -i.bak 's#-pedantic#-mmacosx-version-min=10.10\ -isysroot\ '$SDK'\ -arch\ x86_64\ -arch\ arm64#g' Makefile
if [ $? != 0 ]; then exit; fi
sed -i.bak 's#/opt/local/include#. -I..#g' Makefile
if [ $? != 0 ]; then exit; fi
sed -i.bak 's#/opt/local/lib#.#g' Makefile
if [ $? != 0 ]; then exit; fi
sed -i.bak '/SWORD_CFLAGS =/d' Makefile
if [ $? != 0 ]; then exit; fi
sed -i.bak '/SWORD_LIBS =/d' Makefile
if [ $? != 0 ]; then exit; fi
sed -i.bak '/OPENSSL_LIBS =/d' Makefile
if [ $? != 0 ]; then exit; fi
sed -i.bak 's#-lmimetic# #g' Makefile
if [ $? != 0 ]; then exit; fi
sed -i.bak '/ICU_CFLAGS =/d' Makefile
if [ $? != 0 ]; then exit; fi
sed -i.bak '/ICU_LIBS =/d' Makefile
if [ $? != 0 ]; then exit; fi
sed -i.bak '/XML2_CFLAGS =/d' Makefile
if [ $? != 0 ]; then exit; fi
sed -i.bak '/XML2_LIBS =/d' Makefile
if [ $? != 0 ]; then exit; fi


echo Update the configuration.
sed -i.bak '/HAVE_ICU/d' config.h
if [ $? != 0 ]; then exit; fi
sed -i.bak '/CONFIG_ENABLE_FILE_UPLOAD/d' config/config.h
if [ $? != 0 ]; then exit; fi
rm config/*.bak
rm *.bak


echo Build the Bibledit library.
make -j `sysctl -n hw.logicalcpu_max`
if [ $? != 0 ]; then exit; fi


echo Save the header file.
cp library/bibledit.h ../macos
if [ $? != 0 ]; then exit; fi


echo Clean out stuff no longer needed.
find . -name "*.h" -delete
find . -name "*.cpp" -delete
find . -name "*.c" -delete
find . -name "*.o" -delete
rm *.m4
rm -r autom*cache
rm bibledit
rm compile
rm config.*
rm configure*
rm depcomp
rm dev
rm install-sh
rm missing
rm reconfigure
rm valgrind
find . -name ".deps" -exec rm -r "{}" \; > /dev/null 2>&1
find . -name ".dirstamp" -delete
rm Makefile*
rm server
rm -f unittest
rm stamp-h1
rm generate
rm -rf sources
rm -rf unittests
find .. -name "*.sh" -delete


popd
if [ $? != 0 ]; then exit; fi


echo Build the app.
cd $BIBLEDITMACOS/macos
xcodebuild
if [ $? != 0 ]; then exit; fi


echo To graphically build the app for macOS, open the project in Xcode:
echo open $BIBLEDITMACOS/macos/Bibledit.xcodeproj
echo Then build it from within Xcode
