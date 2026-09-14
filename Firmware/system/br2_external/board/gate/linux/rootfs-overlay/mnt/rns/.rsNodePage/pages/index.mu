> RNS-Gate de R1CBU

Connectivity and services for Reticulum networks

RNS-Gate is a standalone device project for accessing Reticulum and routing traffic. It brings together hardware, Linux firmware and network services for messaging and publishing NomadNet pages directly over Reticulum.

> Hardware

The device is built around an Orange Pi Zero single-board computer, with three boards arranged in a compact stack:

 * Orange Pi Zero - processing, Wi-Fi and 10/100 Mbps Ethernet.
 * A LoRa expansion board with an E22/E32 module connected via SPI.
 * An audio interface board with PTT control for connecting analog HF/VHF radios and using a software modem.

This design brings radio links and IP connections together in a single compact node.

> Software

The Buildroot-based firmware is built as an SD card image. The main networking components are implemented in Rust:

 * rnsd-rs - Reticulum networking and routing.
 * lxmd-rs - LXMF messaging service.
 * nodepage-rs - NomadNet page hosting.

This device already runs rnsd-rs, lxmd-rs and a page server. You are reading one of the pages it hosts.

The build also includes the nomadnet-rs client and components for SX1262 radios and a software modem.

> Capabilities and development

The project is intended for building local network nodes that connect users, link nodes together and host community information pages.

The project design also calls for external RNodes, Bluetooth, USB Wi-Fi adapters in monitor mode and USB connections to DMR radios running OpenGD77.

> Source code

Project overview, hardware documentation and firmware build files:
https://github.com/reticulum-spb/RNS-Gate

Contributions, testing on real hardware and shared experience with building Reticulum networks are welcome.
