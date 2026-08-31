################################################################################
#
#  rsReticulum alsa modem plugin
#
################################################################################

RS_RETICULUM_MODEM_VERSION = f19468e19a94dba4ce1c243856cd53ea87458a19
RS_RETICULUM_MODEM_SITE = https://github.com/reticulum-spb/rsReticulum-modem.git
RS_RETICULUM_MODEM_SITE_METHOD = git
RS_RETICULUM_MODEM_LICENSE = GPLv2

RS_RETICULUM_MODEM_DEPENDENCIES = libcyaml libgpiod alsa-lib liquid-dsp

$(eval $(cmake-package))
