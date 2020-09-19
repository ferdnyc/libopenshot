@echo on
git clone https://github.com/OpenShot/libopenshot-audio
set BUILD_DIR=libopenshot-audio-build-%PLAT_ARCH%
cmake -B %BUILD_DIR% -S libopenshot-audio -DCMAKE_INSTALL_PREFIX=%APPVEYOR_BUILD_FOLDER%\install-%PLAT_ARCH% -DCMAKE_BUILD_TYPE=Debug -G "MinGW Makefiles"
cmake --build %BUILD_DIR% --verbose
cmake --install %BUILD_DIR%
