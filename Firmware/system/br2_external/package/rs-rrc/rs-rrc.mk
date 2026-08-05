################################################################################
#
#  rsRRC
#
################################################################################

RS_RRC_VERSION = 6307592f77ddc5f099c8d7f5a35824d8326de9ff
RS_RRC_SITE = https://github.com/reticulum-spb/rsRRC
RS_RRC_SITE_METHOD = git

define RS_RRC_CREATE_SYMLINK
    ln -sfn $(@D) $(BUILD_DIR)/rsRRC
endef

RS_RRC_POST_EXTRACT_HOOKS += RS_RRC_CREATE_SYMLINK

$(eval $(generic-package))
