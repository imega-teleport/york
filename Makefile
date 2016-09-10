TELEPORT_STORAGE = imegateleport/york
TELEPORT_DATA_PORT ?= 6379
TELEPORT_DATA_IP ?=
PORT = -p 8185:80
EXPECTED = "teleport_storage: user 9915e49a-4de1-41aa-9d7d-c9a687ec048d send data='{\"url\":\"a.imega.club\",\"files\":[\"/9915e49a-4de1-41aa-9d7d-c9a687ec048d/dump.sql\"]}' to a.imega.club?mode=accept-file"

build:
	@docker build -t $(TELEPORT_STORAGE) .

push:
	@docker push $(TELEPORT_STORAGE):latest

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
	@-chmod -R 777 $(CURDIR)/data

discovery_data:
	@while [ "`docker inspect -f {{.State.Running}} teleport_data`" != "true" ]; do \
		echo "wait db"; sleep 0.3; \
	done
	$(eval TELEPORT_DATA_IP = $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' teleport_data))

build/containers/teleport_storage:
	@mkdir -p $(shell dirname $@)
	@docker run -d \
		--name teleport_storage \
		--link teleport_data:teleport_data \
		--restart=always \
		--env REDIS_IP=$(TELEPORT_DATA_IP) \
		--env REDIS_PORT=$(TELEPORT_DATA_PORT) \
		-v $(CURDIR)/data/storage:/data \
		-v $(CURDIR)/app:/app \
		$(PORT) \
		$(TELEPORT_STORAGE)
	@touch $@

build/containers/storage_tester:
	@cd tests;docker build -t imegateleport/storage_tester .

build/containers/teleport_data:
	@mkdir -p $(shell dirname $@)
	@docker run -d --name teleport_data leanlabs/redis
	@touch $@

build/teleport_data_fixture: build/containers/teleport_data discovery_data
	@mkdir -p $(shell dirname $@)
	@docker exec teleport_data \
		sh -c '(echo "SET auth:9915e49a-4de1-41aa-9d7d-c9a687ec048d 8c279a62-88de-4d86-9b65-527c81ae767a";sleep 1) | redis-cli --pipe'
	@docker run --rm --link teleport_data:teleport_data alpine:3.3 \
		sh -c "(echo -e \"SET user:9915e49a-4de1-41aa-9d7d-c9a687ec048d '{\042login\042:\0429915e49a-4de1-41aa-9d7d-c9a687ec048d\042,\042url\042:\042a.imega.club\042,\042email\042:\042teleport@imega.club\042,\042create\042:\042\042,\042pass\042:\042\042}'\";sleep 1) | nc teleport_data 6379"
	@touch $@

test-old: data_dir build/teleport_data_fixture build/containers/teleport_storage build/containers/storage_tester
	@docker run --rm \
		--link teleport_storage:storage \
		-v $(CURDIR)/tests/fixtures:/data/storage \
		imegateleport/storage_tester \
		rsync --inplace -av /data/storage/9915e49a-4de1-41aa-9d7d-c9a687ec048d rsync://storage/data

accert:
	$(eval ACCERT = $(shell docker logs --tail=1 teleport_storage | sed 's/.*	//g'))
	@if [ "$(ACCERT)" != "$(shell echo $(EXPECTED))" ];then \
		exit 1; \
	fi

test: data_dir build/teleport_data_fixture build/containers/teleport_storage
	cd tests/download-complete; make test

.PHONY: build
