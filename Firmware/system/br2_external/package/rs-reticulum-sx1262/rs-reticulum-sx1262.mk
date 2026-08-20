################################################################################
#
#  rsReticulum SX1262 plugin
#
################################################################################

RS_RETICULUM_SX1262_VERSION = 8c840a15028702f9bb258ebec7716508846587d5
RS_RETICULUM_SX1262_SITE = https://github.com/reticulum-spb/rsReticulum-sx1262.git
RS_RETICULUM_SX1262_SITE_METHOD = git
RS_RETICULUM_SX1262_LICENSE = GPLv2

RS_RETICULUM_SX1262_DEPENDENCIES = libcyaml libgpiod

define RS_RETICULUM_SX1262_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/sx1262.so $(TARGET_DIR)/usr/lib/reticulum-rs/sx1262.so
endef

$(eval $(cmake-package))
