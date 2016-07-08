IMAGE = imegateleport/york
CONTAINERS = imega_york
PORT = -p 8187:80
EXPECTED = "teleport_manager: user 9915e49a-4de1-41aa-9d7d-c9a687ec048d send data='{\"url\":\"a.imega.club\",\"files\":[\"/9915e49a-4de1-41aa-9d7d-c9a687ec048d/dump.sql\"]}' to a.imega.club?mode=accept-file"
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
	@-rm -rf data/*

data_dir:
	@-mkdir -p $(CURDIR)/data/zip $(CURDIR)/data/unzip $(CURDIR)/data/parse $(CURDIR)/data/storage

build/containers/teleport_manager:
	@mkdir -p $(shell dirname $@)
	@docker run -d \
		--name teleport_manager \
		--link teleport_data:teleport_data \
		--restart=always \
		-v $(CURDIR)/data/storage:/data \
		$(TELEPORT_MANAGER)
	@touch $@

build/containers/teleport_tester:
	@cd tests;docker build -t imegateleport/manager_tester .

build/containers/teleport_data:
	@mkdir -p $(shell dirname $@)
	@docker run -d --name teleport_data leanlabs/redis
	@touch $@

build/teleport_data_fixture: build/containers/teleport_data
	@mkdir -p $(shell dirname $@)
	@while [ "`docker inspect -f {{.State.Running}} teleport_data`" != "true" ]; do \
		echo "wait db"; sleep 0.3; \
	done
	$(eval REDIS_IP = $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' teleport_data))
	@docker exec teleport_data \
		sh -c '(echo "SET auth:9915e49a-4de1-41aa-9d7d-c9a687ec048d 8c279a62-88de-4d86-9b65-527c81ae767a";sleep 1) | redis-cli --pipe'
	@docker run --rm --link teleport_data:teleport_data alpine:3.3 \
		sh -c "(echo -e \"SET user:9915e49a-4de1-41aa-9d7d-c9a687ec048d '{\042login\042:\0429915e49a-4de1-41aa-9d7d-c9a687ec048d\042,\042url\042:\042a.imega.club\042,\042email\042:\042teleport@imega.club\042,\042create\042:\042\042,\042pass\042:\042\042}'\";sleep 1) | nc teleport_data 6379"
	@touch $@

test: data_dir build/teleport_data_fixture build/containers/teleport_manager build/containers/teleport_tester
	@docker run --rm \
		--link teleport_manager:manager \
		-v $(CURDIR)/tests/fixtures:/data/storage \
		imegateleport/manager_tester \
		rsync --inplace -av /data/storage/9915e49a-4de1-41aa-9d7d-c9a687ec048d rsync://manager/data

accert:
	$(eval ACCERT = $(shell docker logs --tail=1 teleport_manager | sed 's/.*	//g'))
	@if [ "$(ACCERT)" != "$(shell echo $(EXPECTED))" ];then \
		exit 1; \
	fi

.PHONY: build
