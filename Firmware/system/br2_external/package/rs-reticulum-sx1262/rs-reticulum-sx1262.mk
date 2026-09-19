################################################################################
#
#  rsReticulum SX1262 plugin
#
################################################################################

RS_RETICULUM_SX1262_VERSION = c9236e17692070b351fd79c8ac03a8c999bd5619
RS_RETICULUM_SX1262_SITE = https://github.com/reticulum-spb/rsReticulum-sx1262.git
RS_RETICULUM_SX1262_SITE_METHOD = git
RS_RETICULUM_SX1262_LICENSE = GPLv2

RS_RETICULUM_SX1262_DEPENDENCIES = libcyaml libgpiod

define RS_RETICULUM_SX1262_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/sx1262.so $(TARGET_DIR)/usr/lib/reticulum-rs/sx1262.so
endef

$(eval $(cmake-package))
