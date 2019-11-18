OWNER   = punkerside
PROJECT = api

TAG_CLI = base
TAG_API = web
TAG_DB  = db

images:
	@make imagecli
	@make imagedb
	@make imageapi

imagecli:
	docker build -f docker/base/Dockerfile -t $(OWNER)-$(PROJECT):$(TAG_CLI) .

imagedb:
	docker build -f docker/mongodb/Dockerfile -t $(OWNER)-$(PROJECT):$(TAG_DB) .

imageapi:
	docker build -f docker/nodejs/Dockerfile -t $(OWNER)-$(PROJECT):$(TAG_API) .

modules:
	$(eval WHOAMI = $(shell whoami))
	$(eval USERID = $(shell id -u))
	echo 'USERNAME:x:USERID:USERID::/app:/sbin/nologin' > docker/base/passwd
	sed -i 's/USERNAME/$(WHOAMI)/g' docker/base/passwd
	sed -i 's/USERID/$(USERID)/g' docker/base/passwd
	docker run --rm -u $(USERID):$(USERID) -v $(PWD)/docker/base/passwd:/etc/passwd:ro -v $(PWD)/app:/app $(OWNER)-$(PROJECT):$(TAG_CLI) npm install
	rm -rf app/.config/ && rm -rf app/.npm/

sonar:
	./bin/sonar-scanner/bin/sonar-scanner \
	  -Dsonar.projectKey=punkerside_microservice \
	  -Dsonar.organization=punkerside-github \
	  -Dsonar.sources=./app/ \
	  -Dsonar.host.url=https://sonarcloud.io \
	  -Dsonar.login=$(SONAR_TOKEN)

postman:
	docker-compose up -d && sh test/wait.sh
	newman run test/data/webapi_test.postman_test_run --reporters cli
	docker-compose down

publish:
	$(eval VERSION = $(shell date '+%Y%m%d%H%M%S'))
	@make imageapi
	docker tag $(OWNER)-$(PROJECT):$(TAG_API) punkerside/microservice:latest
	docker tag $(OWNER)-$(PROJECT):$(TAG_API) punkerside/microservice:$(VERSION)
	echo "$(DOCKER_PASSWORD)" | docker login -u "$(DOCKER_USERNAME)" --password-stdin
	docker push punkerside/microservice:latest
	docker push punkerside/microservice:$(VERSION)
	@make update VERSION=$(VERSION)

update:
	aws eks --region $(AWS_REGION) update-kubeconfig --name $(EKS_CLUSTER)
	kubectl set image deployments/coffee coffee=punkerside/microservice:$(VERSION)