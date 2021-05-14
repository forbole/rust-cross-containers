#!/usr/bin/env bash

# Version definitions
RUST_VERSION=1.52.1
OSX_SDK=11.1
IOS_SDK=14.4
ANDROID_NDK=r21e

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
    echo "Tool to upload the images to docker hub"
    echo "Usage:"
    printf "\t %s [OPTIONS]\n\n" $0
    echo "OPTIONS:"
    printf "\t--rust <VERSION> \tSpecify which images should be uploaded by the rust version\n"
    printf "\t--osx <VERSION> \tSpecify which osx image should be uploaded by the osx SDK version\n"
    printf "\t--ios <VERSION> \tSpecify which ios image should be uploaded by the ios SDK version\n"
    printf "\t--ndk <VERSION> \tSpecify which android image should be uploaded by the android NDK version\n"
    exit 0
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

declare -a images=("rust-builder:$RUST_VERSION"
                   "windows-rust-builder:$RUST_VERSION"
                   "osx-rust-builder:$RUST_VERSION-$OSX_SDK"
                   "android-rust-builder:$RUST_VERSION-$ANDROID_NDK"
                   "ios-rust-builder:$RUST_VERSION-$IOS_SDK"
                   "wasm-rust-builder:$RUST_VERSION")


for i in "${images[@]}"
do
  if [[ "$(docker images -q "$i" 2> /dev/null)" != "" ]]; then
    echo "Adding forbole tag to: $i"
    docker tag "$i" "forbole/$i"
    docker push "forbole/$i"
    docker image rm "forbole/$i"
  else
    echo "Image $i NOT available, upload skipped"
  fi
done