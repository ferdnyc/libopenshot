@echo on
git clone https://github.com/OpenShot/libopenshot-audio
mkdir libopenshot-audio-build
cd libopenshot-audio-build
cmake -DCMAKE_INSTALL_PREFIX=..\install-cache\%PLAT_ARCH% -G "MinGW Makefiles" ..\libopenshot-audio
cmake --build . -- VERBOSE=1
cmake --build . --target install
