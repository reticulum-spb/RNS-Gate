################################################################################
#
#  rsRRC-client
#
################################################################################

RS_RRC_CLIENT_VERSION = c31425dd3a5fd5aba66528322cfaf84d4fa8665d
RS_RRC_CLIENT_SITE = https://github.com/reticulum-spb/rsRRC-client
RS_RRC_CLIENT_SITE_METHOD = git
RS_RRC_CLIENT_DEPENDENCIES = rs-rrc

define RS_RRC_CLIENT_CREATE_SYMLINK
    ln -sfn $(@D) $(BUILD_DIR)/rsRRC-client
endef

RS_RRC_CLIENT_POST_EXTRACT_HOOKS += RS_RRC_CLIENT_CREATE_SYMLINK

$(eval $(generic-package))
