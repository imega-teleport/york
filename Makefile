IMAGE = imega/york
CONTAINERS = imega_york
PORT = -p 80:80

build:
	@docker build -t $(IMAGE) .

start:
	@docker run -d --name imega_york \
		$(PORT) \
		$(IMAGE)

stop:
	@-docker stop $(CONTAINERS)

clean: stop
	@-docker rm -fv $(CONTAINERS)

destroy: clean
	@docker rmi -f $(IMAGE)
