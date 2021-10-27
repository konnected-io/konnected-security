[![konnected.io](https://raw.githubusercontent.com/konnected-io/docs/master/assets/images/logo-black-small.png)](https://konnected.io)

[![GitHub release](https://img.shields.io/github/release/konnected-io/konnected-security.svg?style=flat-square)](https://github.com/konnected-io/konnected-security/releases)

# Konnected

**Konnected** integrates wired alarm system sensors and sirens to SmartThings, Alexa, Home Assistant, OpenHAB, Hubitat
using the [Konnected Alarm Panel](https://konnected.io) or a ESP8266 development board. 

This is open-source software designed to run on the ESP8266 platform only! This is what powers the
[Konnected Alarm Panel](https://konnected.io) family of ESP8266-based products and is available 
open-source for you to use on any compatible device.

Devices running this software can connect to local home automation platforms using our
[2-way realtime REST API](https://help.konnected.io/support/solutions/articles/32000026804-api-overview) or connect to the 
[Konnected Cloud](https://help.konnected.io/support/solutions/articles/32000028756-provision-a-device-in-konnected-cloud),
a cloud service that enables simple integrations with SmartThings or Alexa (currently free to use!).

This project is built upon the [NodeMCU Lua firmware](https://github.com/nodemcu/nodemcu-firmware).

![alarm-panel-plus-addon-2 3-soona](https://user-images.githubusercontent.com/12016/139100157-5e792dbe-fd08-45c1-8637-7dedfc0ae7ef.jpg)

## Skip this Installation!

[Buy a Konnected Alarm Panel](https://konnected.io), our commercial product that was the inspiration of this open-source
 library. Buying from us is great way to support the developers who have worked hard on this project.

## Getting Started

 1. Flash the device with the latest firmware and filesystem [firmware/releases](firmware/releases) using the instructions in the [Konnected Security Support Documentation](https://help.konnected.io/support/solutions/articles/32000023470-flashing-new-konnected-firmware-software)
 1. Connect to the WiFi network `konnected-security_XXXXXX` to set up WiFi
 1. Follow wiring instructions and application setup instructions in the [Konnected Getting Started Guide](https://help.konnected.io/support/solutions/32000015807)

### Device Drivers

Windows and Mac users will need to download drivers so your computer can talk to the ESP8266 chip over USB. Depending
on which board you have, there are different drivers:

**[Silicon Labs USB to UART drivers](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers)** for:
* all Konnected branded hardware
* development boards with the name _Amica_ on the back
* the small component on the board near the USB port is engraved with SiLABS CP2102

**[WeMos CH340 drivers](https://www.wemos.cc/en/latest/ch340_driver.html)** for boards that:
* have the name _LoLin_ on the back or front
* the small rectangular component on the board near the USB port is engraved with CH340G

### Download Latest Firmware

Go to the [releases section](https://github.com/konnected-io/konnected-security/releases/latest) for a downloadable image
that you can flash on your Konnected Alarm Panel or ESP8266 device.

### Building the Firmware Yourself
Konnected leverages the [NodeMCU](https://github.com/nodemcu/nodemcu-firmware) codebase and [Docker builder](https://hub.docker.com/r/marcelstoer/nodemcu-build/) to create a base nodeMCU firmware image and a filesystem containing the Konnected application. Building only requires a few steps.

1. Download and install [Docker](https://www.docker.com/products/docker-desktop)
1. Clone the Konnected repo

        git clone https://github.com/konnected-io/konnected-security.git

1. Use the build-firmware script to kick off the build - providing a semantic version command line argument as shown below. The build script will automatically pull down the correct nodeMCU image, and use this nodeMCU docker builder to create base firmware, an LFS image, and a SPIFFS file system containing the entire Konnected application.

        cd konnected-security
        ./scripts/build-firmware 2-2-99

1. Once the build completes a folder will be created in `firmware/builds` named after the version specified in the previous step. This folder will contain three files also reflecting the version.
   1. konnected-filesystem-0x100000-2-2-99.img
   1. konnected-firmware-2-2-99.bin
   1. konnected-esp8266-2-2-99.bin
   
The `konnected-firmware-*` contains the firmware partition and should be flashed at location `0x0`.
The `konnected-filesystem-*` image contains the Konnected application and should be flashed at the memory location in
the filename.
For convenience, the `konnected-esp8266-*` image is an all-in-one image to be flashed at memory location `0x0` containing the two images above.

*Note: Each time you build it will remove any prior build outputs corresponding to the same version.*
*Note: Versions in this project should always be formatted `<major>-<minor>-<patch>`.*

### Flashing a Build
Flashing a build is simple with the [NodeMCU PyFlasher](https://github.com/marcelstoer/nodemcu-pyflasher/releases). Simply flash
the `konnected-esp8266-*.bin` file to your device. Typically use baud rate 115200 and flash mode `dio`.

Mac and Linux users can also easily flash from the command line using `esptool`

 1. You must have Python installed with `pip` or `pip3`.
    * **Mac users**: Recommend using [Homebrew](https://brew.sh/) and `brew install python`

 1. Open up a terminal and install `esptool` packages:

        pip3 install esptool

 1. Flash the downloaded image using `esptool`:

         esptool.py --port=/dev/cu.SLAB_USBtoUART write_flash --flash_mode dio --flash_size detect 0x0 konnected-esp8266-3-0-0.bin

 *Note: The USB port may vary depending on your computer platform and board.*




### [For more information, click here for Konnected Documentation, Help and Community support](http://help.konnected.io)


