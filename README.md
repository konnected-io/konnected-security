<img src="https://raw.githubusercontent.com/konnected-io/docs/master/assets/images/logo-black-small.png" />

# Konnected Security

**Konnected Security** integrates wired alarm system sensors and sirens to SmartThings using a NodeMCU based ESP8266 development
 board and (optional) relay. This project consists of a few components:
 
 1. [NodeMCU](http://nodemcu.com/index_en.html) firmware for an ESP8266 development board in `firmware`
 1. Lua and HTML source code for the NodeMCU in `source-code`. All these files should be uploaded to the NodeMCU's 
 internal file system
 1. [SmartThings](https://www.smartthings.com/) platform code in `smartapps` and `devicetypes`
 
![](http://docs.konnected.io/assets/images/konnected-alarm-panel.jpg)

## Skip this Installation!
[Buy a Konnected Security NodeMCU kit from us](https://store.konnected.io) and you can skip the installation! We
pre-load the Konnected Security software on every NodeMCU device before sending it to you. When you get it, just plug it
in connect to WiFi, and it's ready to set up. Buying from us is great way to support
the developers who have worked hard on this project.

## Installation Overview

 1. Install device drivers for your NodeMCU device.
 1. Flash the device with the included firmware [firmware/konnected-security-2-0.bin](firmware/konnected-security-2-0.bin)
 1. Upload all the code in `source-code` to the device and reboot the device.
 1. Connect to the WiFi network `konnected-security_XXXXXX` to set up WiFi
 1. Follow wiring instructions and SmartThings application setup instructions in the [Konnected Security Documentation](http://docs.konnected.io/security-alarm-system)

### Device Drivers

Windows and Mac users will need to download drivers so your computer can talk to the ESP8266 chip over USB. Depending
on which board you have, there are different drivers: 

**[WeMos CH340 drivers](https://www.wemos.cc/downloads)** for boards that:
* have the name _LoLin_ on the back or front
* the small rectangular component on the board near the USB port is engraved with CH340G
* **Mac OS X Sierra users**: [use this driver](http://kig.re/2014/12/31/how-to-use-arduino-nano-mini-pro-with-CH340G-on-mac-osx-yosemite.html)

**[Silicon LabsUSB to UART drivers](http://www.silabs.com/products/mcu/pages/usbtouartbridgevcpdrivers.aspx)** for boards that:
* have the name _Amica_ on the back
* the small component on the board near the USB port is engraved with SiLABS CP2102

### Mac & Linux Users

 1. You must have Python installed with `pip`. Mac users: I recommend using [Homebrew](https://brew.sh/) and `brew install python`
 1. Install `esptool` and `nodemcu-uploader` packages:
     
        pip install esptool
        pip install nodemcu-uploader
        
 1. Run the script in `scripts/flash` to flash and upload the files. You may need to edit the variables
 at the top as your serial port may be different depending on the type of
 NodeMCU development board you have.


### Windows Users

Instructions coming soon!

### Donations

We work hard on this project because we're passionate about making home automation accessible to everybody. Millions of
 homes in North America and worldwide are already wired with sensors and have the potential to become smart homes. We
 want to make this a reality.
 
If you've used Konnected Security and it's improved your life and your home security, please consider [donating](http://docs.konnected.io/donate) to help us
achieve that goal.

Thank you for your support,

@heythisisnate and @copy-ninja

#### [Donate Here](http://docs.konnected.io/donate)

### [For more information click here for the complete Konnected Security Documentation](http://docs.konnected.io/security-alarm-system)


