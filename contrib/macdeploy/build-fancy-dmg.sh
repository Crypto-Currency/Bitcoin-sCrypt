#!/bin/bash

# 1. Dynamically find the .app bundle name in the current directory
APP_NAME=$(ls -d *.app | head -n 1)

if [ -z "$APP_NAME" ]; then
    echo "ERROR: No compiled .app bundle found in this directory!"
    exit 1
fi

echo "Deploying and stitching frameworks for: $APP_NAME"

# 2. Execute baseline macdeployqt routines natively
macdeployqt "$APP_NAME"

# 3. Forcefully pull down ALL core boost components using the dynamic app target folder
FRAMEWORKS="./$APP_NAME/Contents/Frameworks"
cp /usr/local/opt/boost/lib/libboost_atomic.dylib "$FRAMEWORKS/"
cp /usr/local/opt/boost/lib/libboost_container.dylib "$FRAMEWORKS/"
cp /usr/local/opt/boost/lib/libboost_chrono.dylib "$FRAMEWORKS/"
cp /usr/local/opt/boost/lib/libboost_date_time.dylib "$FRAMEWORKS/"

# 4. Grant system modifications permissions to unlock the binaries
chmod 755 "$FRAMEWORKS"/libboost_*.dylib

# 5. Rewrite the Internal Global ID headers of the helper dylibs themselves
install_name_tool -id @loader_path/libboost_atomic.dylib "$FRAMEWORKS/libboost_atomic.dylib"
install_name_tool -id @loader_path/libboost_container.dylib "$FRAMEWORKS/libboost_container.dylib"
install_name_tool -id @loader_path/libboost_chrono.dylib "$FRAMEWORKS/libboost_chrono.dylib"
install_name_tool -id @loader_path/libboost_date_time.dylib "$FRAMEWORKS/libboost_date_time.dylib"

# 6. Route the primary libraries to find their helpers next to them inside the bundle
install_name_tool -change /usr/local/opt/boost/lib/libboost_atomic.dylib @loader_path/libboost_atomic.dylib "$FRAMEWORKS/libboost_filesystem.dylib"
install_name_tool -change /usr/local/opt/boost/lib/libboost_atomic.dylib @loader_path/libboost_atomic.dylib "$FRAMEWORKS/libboost_thread.dylib"
install_name_tool -change /usr/local/opt/boost/lib/libboost_container.dylib @loader_path/libboost_container.dylib "$FRAMEWORKS/libboost_program_options.dylib"
install_name_tool -change /usr/local/opt/boost/lib/libboost_chrono.dylib @loader_path/libboost_chrono.dylib "$FRAMEWORKS/libboost_thread.dylib"
install_name_tool -change /usr/local/opt/boost/lib/libboost_date_time.dylib @loader_path/libboost_date_time.dylib "$FRAMEWORKS/libboost_thread.dylib"

# 7. Strip out the file suffix to generate the clean output naming signature
DMG_NAME="${APP_NAME%.app}.dmg"
VOL_NAME="${APP_NAME%.app} Installer"

# 8. Execute the final canvas assembly layout matching your custom size profile
create-dmg \
  --volname "$VOL_NAME" \
  --background "./contrib/macdeploy/background.png" \
  --window-pos 200 120 \
  --window-size 500 340 \
  --icon-size 110 \
  --icon "$APP_NAME" 115 155 \
  --app-drop-link 385 155 \
  "$DMG_NAME" \
  "./$APP_NAME"
