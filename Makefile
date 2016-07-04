IMAGE = imegateleport/york
CONTAINERS = imega_york
PORT = -p 8187:80

TELEPORT_MANAGER ?= imegateleport/york

build:
	@docker build -t $(IMAGE) .

get_containers:
	$(eval CONTAINERS := $(subst build/containers/,,$(shell find build/containers -type f)))

stop: get_containers
	@-docker stop $(CONTAINERS)

clean: stop
	@-docker rm -fv $(CONTAINERS)
	@-rm -rf build/containers/*

data_dir:
	@-mkdir -p $(CURDIR)/data/zip $(CURDIR)/data/unzip $(CURDIR)/data/parse $(CURDIR)/data/storage

build/containers/teleport_manager:
	@mkdir -p $(shell dirname $@)
	@docker run -d \
		--name teleport_manager \
		--restart=always \
		-v $(CURDIR)/data/storage:/data \
		$(TELEPORT_MANAGER)
	@touch $@

build/containers/teleport_tester:
	@cd tests;docker build -t imegateleport/manager_tester .

test: data_dir build/containers/teleport_manager build/containers/teleport_tester
	@docker run --rm \
		--link teleport_manager:manager \
		-v $(CURDIR)/tests/fixtures:/data/storage \
		imegateleport/manager_tester \
		rsync --inplace -av /data/storage/9915e49a-4de1-41aa-9d7d-c9a687ec048d rsync://manager/data
	@if [ ! -f "$(CURDIR)/data/unzip/9915e49a-4de1-41aa-9d7d-c9a687ec048d/import.xml" ];then \
		exit 1; \
	fi

.PHONY: build
