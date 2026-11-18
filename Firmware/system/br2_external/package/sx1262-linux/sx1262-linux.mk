################################################################################
# sx1262-linux
################################################################################

SX1262_LINUX_VERSION = 9b6de3c708e8a882af73df8e5181e7b6a279243c
SX1262_LINUX_SITE = https://github.com/strijar/sx1262-linux
SX1262_LINUX_SITE_METHOD = git
SX1262_LINUX_LICENSE = GPL-2.0-only
SX1262_LINUX_LICENSE_FILES = COPYING
SX1262_LINUX_INSTALL_STAGING = YES

define SX1262_LINUX_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0644 $(@D)/include/uapi/linux/sx1262.h \
		$(STAGING_DIR)/usr/include/linux/sx1262.h
endef

$(eval $(kernel-module))
$(eval $(generic-package))
