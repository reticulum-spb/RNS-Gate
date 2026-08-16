# RNS-Gate

## Objective

Create a standalone device for access and routing within the Reticulum Network Stack 

## Interfaces for accessing other network nodes

* Integrated:
  - LoRa module (E22/E32 via SPI)
  - WiFi
  - Bluetooth
  - 10/100 Ethernet
* External:
  - RNode (via USB or Bluetooth)
  - WiFi in monitor mode (via USB)
* Audio access and PTT control for connecting analog VHF and HF radios with soft modem implementation 
* Connection of DMR stations via USB (OpenGD77 firmware) 

## Access to user devices

* BlueTooth 
* IP via WiFi and Ethernet

## Implementation

A 3-component "tower":

* Single-board computer based on Orange Pi Zero 
* Add-on board with an E22/E32 LoRa module 
* Add-on board with an HF/VHF audio interface

## Device configuration

Web interface over IP

## Building with Docker

The build runs inside a container and the working tree is stored
in the named volume `rns-gate-build`. This allows the toolchain, download cache
(`dl/`), and ccache to be reused across builds.

```sh
cd Firmware
./docker-build.sh              # full build -> docker/output/sdcard.img
./docker-build.sh config       # reset .config from defconfig (fast)
./docker-build.sh menuconfig   # edit and export a candidate defconfig
```

`menuconfig` edits the release-specific `.config` in the volume and exports a
minimal defconfig to `docker/output/gate_zero_defconfig`. A full build always
reapplies the defconfig from the repository, so review the exported file first.
To make the changes permanent, use it to replace `system/br2_external/configs/gate_zero_defconfig`.
