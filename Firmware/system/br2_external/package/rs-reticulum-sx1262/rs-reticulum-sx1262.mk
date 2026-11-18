################################################################################
#
#  rsReticulum SX1262 plugin
#
################################################################################

RS_RETICULUM_SX1262_VERSION = b0d63b43bdc3a008debccec1da3f165e74616e40
RS_RETICULUM_SX1262_SITE = https://github.com/reticulum-spb/rsReticulum-sx1262.git
RS_RETICULUM_SX1262_SITE_METHOD = git
RS_RETICULUM_SX1262_LICENSE = GPLv2

RS_RETICULUM_SX1262_DEPENDENCIES = libcyaml
RS_RETICULUM_SX1262_CONF_OPTS += -DCMAKE_C_FLAGS="-Wno-error=unused-result"

define RS_RETICULUM_SX1262_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/sx1262.so $(TARGET_DIR)/usr/lib/reticulum-rs/sx1262.so
endef

$(eval $(cmake-package))
