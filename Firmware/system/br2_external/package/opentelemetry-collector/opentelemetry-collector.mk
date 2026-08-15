################################################################################
#
# opentelemetry-collector (minimal ARMv7 distribution)
#
################################################################################

OPENTELEMETRY_COLLECTOR_VERSION = local
OPENTELEMETRY_COLLECTOR_SITE = $(BR2_EXTERNAL_GATE_PATH)/package/opentelemetry-collector
OPENTELEMETRY_COLLECTOR_SITE_METHOD = local
OPENTELEMETRY_COLLECTOR_OVERRIDE_SRCDIR_RSYNC_EXCLUSIONS = \
	--exclude .DS_Store \
	--exclude ocb \
	--exclude otelarmv7col
OPENTELEMETRY_COLLECTOR_DEPENDENCIES = host-go
OPENTELEMETRY_COLLECTOR_BIN_NAME = otelarmv7col
OPENTELEMETRY_COLLECTOR_LDFLAGS = -s -w
OPENTELEMETRY_COLLECTOR_GO_ENV = \
	GO111MODULE=on \
	GOOS=linux \
	GOARCH=arm \
	GOARM=7 \
	CGO_ENABLED=0 \
	GOTOOLCHAIN=local \
	GOROOT="$(HOST_DIR)/lib/go" \
	GOCACHE="$(HOST_DIR)/share/go-cache" \
	GOMODCACHE="$(HOST_DIR)/share/go-path/pkg/mod" \
	GOPROXY=https://proxy.golang.org,direct

define OPENTELEMETRY_COLLECTOR_BUILD_CMDS
	cd $(@D)/generated && \
		$(OPENTELEMETRY_COLLECTOR_GO_ENV) \
		$(HOST_DIR)/bin/go build \
			-buildvcs=false \
			-mod=readonly \
			-trimpath \
			-ldflags "$(OPENTELEMETRY_COLLECTOR_LDFLAGS)" \
			-o ../$(OPENTELEMETRY_COLLECTOR_BIN_NAME) \
			.
endef

define OPENTELEMETRY_COLLECTOR_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 \
		$(@D)/$(OPENTELEMETRY_COLLECTOR_BIN_NAME) \
		$(TARGET_DIR)/usr/bin/$(OPENTELEMETRY_COLLECTOR_BIN_NAME)
endef

$(eval $(generic-package))
