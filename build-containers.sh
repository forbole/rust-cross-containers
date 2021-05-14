#!/usr/bin/env bash

# Utility consts
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
files_root="$script_dir/files"
logs_dir="$script_dir/logs"

# Exit when command fails
set -e

# Version definitions
RUST_VERSION=1.52.1
XCODE_VERSION=12.5
OSX_SDK=11.1
IOS_SDK=14.4
ANDROID_NDK=r21e
OSX_BUILT=
IOS_BUILT=

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --rust)
    RUST_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --xcode)
    XCODE_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --osx)
    OSX_SDK="$2"
    shift # past argument
    shift # past value
    ;;
    --ios)
    IOS_SDK="$2"
    shift # past argument
    shift # past value
    ;;
    --ndk)
    ANDROID_NDK="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    shift # past argument
    echo "Rust cross compilation images builder"
    echo "Usage:"
    printf "\t %s [OPTIONS]\n\n" $0
    echo "OPTIONS:"
    printf "\t--rust <VERSION> \tSpecify the rust version that will be installed inside the images\n"
    printf "\t--xcode <VERSION> \tSpecify the version of the xcode package inside the files directory\n"
    printf "\t--osx <VERSION> \tSpecify the osx sdk version to install inside the osx-rust-builder image\n"
    printf "\t--ios <VERSION> \tSpecify the ios sdk version to install inside the ios-rust-builder image\n"
    printf "\t--ndk <VERSION> \tSpecify the android ndk version to install inside the android-rust-builder image\n"
    exit 0
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo "Will be generated the following docker images:"
echo "- Linux: rust-builder:$RUST_VERSION"
echo "- Windows: windows-rust-builder:$RUST_VERSION"
echo "- MacOSX: osx-rust-builder:$RUST_VERSION-$OSX_SDK"
echo "- Android: android-rust-builder:$RUST_VERSION-$ANDROID_NDK"
echo "- iOS: ios-rust-builder:$RUST_VERSION-$IOS_SDK"
echo "- WASM: wasm-rust-builder:$RUST_VERSION"

read -p "Continue? [y/n]" -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Preparing the log directory
rm -R "$logs_dir/" | true && mkdir "$logs_dir" | true

echo "Checking iOS and macOS sdk files..."

if [ ! -e "$files_root/MacOSX${OSX_SDK}.sdk.tar.xz" ] || [ ! -e "$files_root/iPhoneOS${IOS_SDK}.sdk.tar.xz" ] || [ ! -e "$files_root/iPhoneSimulator${IOS_SDK}.sdk.tar.xz" ]; then
  if [ ! -e "$files_root/Xcode_${XCODE_VERSION}.xip" ]; then
    echo "$files_root/Xcode_${XCODE_VERSION}.xip is required. It can be downloaded from https://developer.apple.com/download/more/ with a valid apple ID."
  else
    echo "Preparing extractor container..."
    docker build -t "xcode-packer:latest" -f "$script_dir/Dockerfile.xcode" "$script_dir" 2>&1 | tee "$logs_dir/xcode.log"
    echo "Building OSX and iOS SDK packages. This will take a while..."
    docker run -it --rm -v "${files_root}":/root/files xcode-packer:latest 2>&1 | tee "$logs_dir/xcode_packer.log"
  fi
fi

# Exit when command piped too tee fails
set -o pipefail

echo "Preparing the base builder 'rust-builder' container"
docker build -t "rust-builder:$RUST_VERSION" \
  --build-arg "RUST_VERSION=$RUST_VERSION" \
  -f "$script_dir/Dockerfile.base" "$script_dir" 2>&1 | tee "$logs_dir/rust-builder.log"

echo "Preparing 'windows-rust-builder' container"
docker build -t "windows-rust-builder:$RUST_VERSION" \
  --build-arg "RUST_VERSION=$RUST_VERSION" \
  -f "$script_dir/Dockerfile.windows" "$script_dir" 2>&1 | tee "$logs_dir/windows-rust-builder.log"

if [ -e "$files_root/MacOSX${OSX_SDK}.sdk.tar.xz" ]; then
  echo "Generating 'osx-rust-builder' image"
  docker build -t "osx-rust-builder:$RUST_VERSION-$OSX_SDK" \
    --build-arg "RUST_VERSION=$RUST_VERSION" \
    --build-arg "OSX_SDK=$OSX_SDK" \
    -f "$script_dir/Dockerfile.osx" "$script_dir" 2>&1 | tee "$logs_dir/osx-rust-builder.log"
  OSX_BUILT="true"
else
  echo "Skipping osx-rust-builder image generation." | tee "$logs_dir/osx-rust-builder.log"
  echo "MacOSX${OSX_SDK}.sdk.tar.xz not found inside the files directory" | tee -a "$logs_dir/osx-rust-builder.log"
fi

echo "Preparing 'android-rust-builder' container"
docker build -t "android-rust-builder:$RUST_VERSION-$ANDROID_NDK" \
  --build-arg "RUST_VERSION=$RUST_VERSION" \
  --build-arg "NDK_VERSION=$ANDROID_NDK" \
  -f "$script_dir/Dockerfile.android" "$script_dir" 2>&1 | tee "$logs_dir/android-rust-builder.log"

if [ -e "$files_root/iPhoneOS${IOS_SDK}.sdk.tar.xz" ] && [ -e "$files_root/iPhoneSimulator${IOS_SDK}.sdk.tar.xz" ]; then
  echo "Preparing 'ios-rust-builder' container"
  docker build -t "ios-rust-builder:$RUST_VERSION-$IOS_SDK" \
    --build-arg "RUST_VERSION=$RUST_VERSION" \
    --build-arg "IOS_SDK=$IOS_SDK" \
    -f "$script_dir/Dockerfile.ios" "$script_dir" 2>&1 | tee "$logs_dir/ios-rust-builder.log"
  IOS_BUILT="true"
else
  echo "Skipping ios-rust-builder image generation." | tee "$logs_dir/ios-rust-builder.log"
  if [ ! -e "$files_root/iPhoneOS${IOS_SDK}.sdk.tar.xz" ]; then
    echo "iPhoneOS${IOS_SDK}.sdk.tar.xz not found inside the files directory" | tee -a "$logs_dir/ios-rust-builder.log"
  fi
  if [ ! -e "$files_root/iPhoneSimulator${IOS_SDK}.sdk.tar.xz" ]; then
    echo "iPhoneSimulator${IOS_SDK}.sdk.tar.xz not found inside the files directory" | tee -a "$logs_dir/ios-rust-builder.log"
  fi
fi

echo "Preparing 'wasm-rust-builder' container"
docker build -t "wasm-rust-builder:$RUST_VERSION" \
  --build-arg "RUST_VERSION=$RUST_VERSION" \
  -f "$script_dir/Dockerfile.wasm" "$script_dir" 2>&1 | tee "$logs_dir/wasm-rust-builder.log"

# Restore original pipe settings
set +o pipefail

echo "Images generated successfully!!"
echo "- Linux: rust-builder:$RUST_VERSION"
echo "- Windows: windows-rust-builder:$RUST_VERSION"
if [ ! -z $OSX_BUILT ]; then
  echo "- MacOSX: osx-rust-builder:$RUST_VERSION-$OSX_SDK"
fi
echo "- Android: android-rust-builder:$RUST_VERSION-$ANDROID_NDK"
if [ ! -z $IOS_BUILT ]; then
  echo "- iOS: ios-rust-builder:$RUST_VERSION-$IOS_SDK"
fi
echo "- WASM: wasm-rust-builder:$RUST_VERSION"
