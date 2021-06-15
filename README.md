# Rust cross containers
This repo contains a set of Docker images to easily crosscompile rust code to different targets.  

See this table for the available images and the supported targets.

| Image | Rust target |
| ------------- | ------ |
| rust-builder | `x86_64-unknown-linux-gnu` |
| windows-rust-builder| `x86_64-pc-windows-gnu` |
| osx-rust-builder | `x86_64-apple-darwin` |
| android-rust-builder | `armv7-linux-androideabi` `aarch64-linux-android` `x86_64-linux-android` `i686-linux-android` |
| ios-rust-builder | `aarch64-apple-ios` `x86_64-apple-ios` |
| wasm-rust-builder | `wasm32-unknown-unknown` |

## Images usage
In this section we describe how to use the images, the examples uses our prebuilt images from [Docker hub](https://hub.docker.com/u/forbole).  
All the images are tagged with the installed rust version and for some of them also the version of the target device sdk.
For example `android-rust-builder:1.52.1-r21e` means that the image have rust 1.52.1 with android NDK version r21e.  
If you prefer to build the images by yourself you can follow the steps from the **Images generation** section.

### rust-builder
This image can be used to compile a rust project for a linux with glibc.  
To compile a project just run the following command within the project directory.
```bash
$ docker run --rm -v $(pwd):/workdir forbole/rust-builder:1.52.1 \
		cargo build --release --target=x86_64-unknown-linux-gnu
```

### windows-rust-builder
This image can be used to compile a rust project for windows.  
To compile a project just run the following command within the project directory.
```bash
$ docker run --rm -v $(pwd):/workdir forbole/windows-rust-builder:1.52.1 \
		cargo build --release --target=x86_64-pc-windows-gnu
```

### osx-rust-builder
This image can be used to compile a rust project for osx.  
To compile a project just run the following command within the project directory.
```bash
$ docker run --rm -v $(pwd):/workdir forbole/osx-rust-builder:1.52.1-11.1 \
		cargo build --release --target=x86_64-apple-darwin
```

### android-rust-builder
This image can be used to compile a rust project for a device with android.  
To compile a project just run the following command within the project directory.
```bash
$ docker run --rm -v $(pwd):/workdir forbole/android-rust-builder:1.52.1-r21e \
		cargo build --release --target=<ANDROID_TARGET>
```

### ios-rust-builder
This image can be used to compile a rust project for a device with iOS.  
To compile a project just run the following command within the project directory.
```bash
$ docker run --rm -v $(pwd):/workdir -e IOS_ARCH=<arm64|x86_64> forbole/ios-rust-builder:1.52.1-14.4 \
		cargo build --release --target=<IOS_TARGET>
```
**NOTE:** Since at the moment the image is not able to select the correct ios SDK based on the cargo target
you need to pass the extra environment variable **IOS_ARCH** that specify the target device architecture.

So the value of **IOS_ARCH** should be `arm64` if the target is `arch64-apple-ios` or 
`x86_64` if the target is `x86_64-apple-ios`.

### wasm-rust-builder
This image can be used to compile a rust project to WASM.  
To compile the project just run the following command within the project directory.
```bash
$ docker run --rm -v $(pwd):/workdir forbole/windows-rust-builder:1.52.1 \
		cargo build --release --target=wasm32-unknown-unknown
```
Inside this image is also available [wasm-pack](https://github.com/rustwasm/wasm-pack) 
if you need to generate a WASM package that you would like to interop with JavaScript.

## Images generation
:warning: To generates the ios and osx images you need to download the XCode `.xip` file from the
[Apple Developer portal](https://developer.apple.com/download/more/) (Tested with XCode 12.5)
and place it inside the **files** folder.  
If you don't want build the images by yourself we have some prebuilt images available on 
[Docker hub](https://hub.docker.com/u/forbole).

To generates the docker images simply run the `build-containers.sh` script.  
The script also allows to select the version of the tools that will be installed inside the images.  
In the table below you can find what can be customized.

| Parameter | Description | Default value |
| --------- | ----------- | ------------- |
| --rust | Specify the rust version that will be installed inside the images | 1.52.1 |
| --xcode | Specify the version of the xcode package present in the files directory from which the ios and osx sdks will be extracted. | 12.5 |
| --osx | Specify the osx sdk version to install inside the osx-rust-builder image | 11.1 |
| --ios | Specify the ios sdk version to install inside the ios-rust-builder image | 14.4 |
| --ndk | Specify the Android ndk version to install inside the android-rust-builder image | r21e |
