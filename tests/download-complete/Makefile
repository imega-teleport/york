DOCKER_RM = false

test:
	@docker run --rm=$(DOCKER_RM) \
		-v $(CURDIR):/data \
		-w /data \
		--link teleport_storage:storage \
		alpine \
		sh -c 'apk add --update bash curl && ./test_download_complete.sh storage'
