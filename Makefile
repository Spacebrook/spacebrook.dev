TAG=$(shell git rev-parse HEAD | cut -c -16)

default: run

build:
	docker build -t spacebrook.dev .

run: build
	docker run -it -p 80:80 -p 443:443 --hostname spacebrook-local spacebrook.dev

push: build
	docker tag spacebrook.dev spacebrook/spacebrook.dev:$(TAG)
	docker push spacebrook/spacebrook.dev:$(TAG)

release: push
	ssh root@spacebrook.dev ./upgrade.sh $(TAG)
