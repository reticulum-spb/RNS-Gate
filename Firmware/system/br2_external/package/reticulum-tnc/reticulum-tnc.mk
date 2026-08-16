################################################################################
#
#  Reticulum-TNC daemon
#
################################################################################

RETICULUM_TNC_VERSION = 200c4a0a88e887f2884cd5a35ec35efef5f04812
RETICULUM_TNC_SITE = https://github.com/reticulum-spb/Reticulum-TNC.git
RETICULUM_TNC_SITE_METHOD = git
RETICULUM_TNC_LICENSE = GPLv2

RETICULUM_TNC_DEPENDENCIES = libcyaml alsa-lib libgpiod liquid-dsp

define RETICULUM_TNC_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/rtnc_modem $(TARGET_DIR)/usr/bin/rtnc_modem
    $(INSTALL) -D -m 0755 $(@D)/rtnc_radio_calibrate $(TARGET_DIR)/usr/bin/rtnc_radio_calibrate
    $(INSTALL) -D -m 0755 $(@D)/rtnc_ota_benchmark $(TARGET_DIR)/usr/bin/rtnc_ota_benchmark
endef

$(eval $(cmake-package))
