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

## Сборка образа в Docker

Сборка идёт внутри контейнера, рабочее дерево Buildroot лежит в именованном
volume `rns-gate-build`, а не на диске macOS. За счёт этого toolchain, кэш
загрузок (`dl/`) и ccache переиспользуются между запусками — повторные сборки
намного быстрее. Каталог сборки отдельный для каждой версии Buildroot, чтобы
не смешивать несовместимые package stamps и host tools. На хост копируется
только готовый `sdcard.img`.

```sh
cd Firmware
./docker-build.sh              # полная сборка -> docker/output/sdcard.img
./docker-build.sh config       # сбросить .config из defconfig (быстро)
./docker-build.sh menuconfig   # изменить и выгрузить кандидат defconfig
```

`menuconfig` правит release-specific `.config` в volume и выгружает минимальный
defconfig в `docker/output/gate_zero_defconfig`. Полная сборка всегда заново
применяет defconfig из репозитория, поэтому экспортированный файл нужно сначала
просмотреть и, если изменения надо закрепить, заменить им
`system/br2_external/configs/gate_zero_defconfig`.

Сбросить кэш целиком: `docker volume rm rns-gate-build`.
