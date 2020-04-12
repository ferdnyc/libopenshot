git clone https://github.com/OpenShot/libopenshot-audio
mkdir libopenshot-audio-build
cd libopenshot-audio-build
cmake -DCMAKE_INSTALL_PREFIX=..\build\install-x64 -G "MinGW Makefiles" ..\libopenshot-audio
cmake --build . -- VERBOSE=1
mingw32-make install
cd ..
:end
