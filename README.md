[![konnected.io](https://raw.githubusercontent.com/konnected-io/docs/master/assets/images/logo-black-small.png)](https://konnected.io)

[![GitHub release](https://img.shields.io/github/release/konnected-io/konnected-security.svg?style=flat-square)](https://github.com/konnected-io/konnected-security/releases)

# Konnected

**Konnected** integrates wired alarm system sensors and sirens to SmartThings, Home Assistant, OpenHAB, or Hubitat using a NodeMCU based ESP8266 development board and (optional) relay. This project consists of a few components:
 
 1. [NodeMCU](http://nodemcu.com/index_en.html) based firmware for an ESP8266 development board in `firmware`
 1. Lua and HTML source code for the NodeMCU in `src`. All these files are built into a SPIFFS file system which runs on NodeMCU
 1. [SmartThings](https://www.smartthings.com/) platform code in `smartapps` and `devicetypes`
 
![](http://docs.konnected.io/assets/images/konnected-alarm-panel.jpg)

## Skip this Installation!

[Buy a Konnected Alarm Panel](https://konnected.io), our commercial product that was the inspiration of this open-source
 library. Buying from us is great way to support the developers who have worked hard on this project.

## Getting Started

 1. Flash the device with the latest firmware and filesystem [firmware/releases](firmware/releases) using the instructions in the [Konnected Security Support Documentation](https://help.konnected.io/support/solutions/articles/32000023470-flashing-new-konnected-firmware-software)
 1. Connect to the WiFi network `konnected-security_XXXXXX` to set up WiFi
 1. Follow wiring instructions and application setup instructions in the [Konnected Security Documentation](http://docs.konnected.io/security-alarm-system)

#### Note on Device Drivers

Windows and Mac users will need to download drivers so your computer can talk to the ESP8266 chip over USB. Depending
on which board you have, there are different drivers: 

**[WeMos CH340 drivers](https://www.wemos.cc/en/latest/ch340_driver.html)** for boards that:
* have the name _LoLin_ on the back or front
* the small rectangular component on the board near the USB port is engraved with CH340G
* **Mac OS X Sierra users**: [use this driver](http://kig.re/2014/12/31/how-to-use-arduino-nano-mini-pro-with-CH340G-on-mac-osx-yosemite.html)

**[Silicon Labs USB to UART drivers](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers)** for boards that:
* have the name _Amica_ on the back
* the small component on the board near the USB port is engraved with SiLABS CP2102

### Building the Firmware
Konnected leverages the [NodeMCU](https://github.com/nodemcu/nodemcu-firmware) codebase and [Docker builder](https://hub.docker.com/r/marcelstoer/nodemcu-build/) to create a base nodeMCU firmware image and a filesystem containing the Konnected application. Building only requires a few steps.

1. Download and install [Docker](https://www.docker.com/products/docker-desktop)
1. Clone the Konnected and nodeMCU repos to the same level in your working directory

        git clone https://github.com/konnected-io/konnected-security.git
        git clone https://github.com/nodemcu/nodemcu-firmware.git

1. Check out the 2.2.1 release of nodemcu

        pushd nodemcu-firmware && git checkout 2.2.1-master_20190405 && popd

1. Use the build-firmware script to kick off the build - providing a semantic version command line argument as shown below. The build script will automatically pull down the nodeMCU docker builder, build the base firmware, create an LFS image, and build a SPIFFS file system containing the entire Konnected application.

        cd konnected-security
        ./scripts/build-firmware 2-2-99

1. Once the build completes a folder will be created in `firmware/builds` named after the version specified in the previous step. This folder will contain two files also reflecting the version.
   1. konnected-filesystem-0x100000-2-2-99.img
   1. konnected-firmware-2-2-99.bin

*Note: Each time you build it will remove any prior build outputs corresponding to the same version.*
*Note: Versions in this project should always be formatted `<major>-<minor>-<patch>`.*

### Flashing a Build
Flashing a build is simple with the [Konnected Flashing Tool](https://help.konnected.io/support/solutions/articles/32000023470-flashing-new-konnected-firmware-software).

Mac and Linux users can also easily flash from the command line using [scripts/flash](scripts/flash).

 1. You must have Python installed with `pip` or `pip3`. 
    * **Mac users**: I recommend using [Homebrew](https://brew.sh/) and `brew install python`  
 
 1. Open up a terminal and install `esptool` packages:
     
        pip3 install esptool
        
 1. Run the script in `scripts/flash` to flash the firmware and software to the device. You must pass in version and serial port args. The flash script will always attempt to flash a matching version in `firmware/builds` before falling back to `firmware/releases`

         ./scripts/flash 2-2-99 /dev/ttyS3
 
 *Note: You may also need to make the script executable by running `chmod 755 scripts/flash`.*
 

### Donations

We work hard on this project because we're passionate about making home automation accessible to everybody. Millions of
 homes in North America and worldwide are already wired with sensors and have the potential to become smart homes. We
 want to make this a reality.
 
If you've used Konnected Security and it's improved your life and your home security, please consider [donating](http://docs.konnected.io/donate) to help us
achieve that goal.

Thank you for your support,

Nate Clark
**@heythisisnate**


### [For more information, click here for Konnected Documentation, Help and Community support](http://help.konnected.io)


