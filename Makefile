OWNER      = punkerside
PROJECT    = api
ENV        = dev

AWS_REGION = us-east-1
AWS_ZONE_A = $(shell aws ec2 describe-availability-zones --region $(AWS_REGION) --query 'AvailabilityZones[*].[ZoneName]' --filters "Name=state,Values=available" --output text | sed '1!d')
AWS_ZONE_B = $(shell aws ec2 describe-availability-zones --region $(AWS_REGION) --query 'AvailabilityZones[*].[ZoneName]' --filters "Name=state,Values=available" --output text | sed '2!d')
KUBECONFIG = "$(HOME)/.kube/eksctl/clusters/$(PROJECT)-$(ENV)"

WHOAMI  = $(shell whoami)
USERID  = $(shell id -u)
VERSION = $(shell date '+%y%m%d%H%M')

image-base:
	docker build -f docker/base/Dockerfile -t $(PROJECT)-$(ENV):base .

image-build:
	docker build -f docker/build/Dockerfile --build-arg IMAGE=$(PROJECT)-$(ENV):base -t $(PROJECT)-$(ENV):build .

image-app:
	docker build -f docker/app/Dockerfile --build-arg IMAGE=$(PROJECT)-$(ENV):base -t $(PROJECT)-$(ENV):app .

code-scanner:
	curl -o sonar-scanner-cli-4.2.0.1873-linux.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.2.0.1873-linux.zip
	unzip sonar-scanner-cli-4.2.0.1873-linux.zip && mv sonar-scanner-4.2.0.1873-linux/ sonar-scanner/ && rm -rf sonar-scanner-cli-4.2.0.1873-linux.zip
	./sonar-scanner/bin/sonar-scanner \
	  -Dsonar.projectKey=microservice-ci \
	  -Dsonar.organization=punkerside-github \
	  -Dsonar.sources=./app/ \
	  -Dsonar.host.url=https://sonarcloud.io \
	  -Dsonar.login=bc177829f542354dec2c8d06741a7790551fd926

code-build:
	echo 'USERNAME:x:USERID:USERID::/app:/sbin/nologin' > docker/build/passwd
	sed -i 's/USERNAME/$(WHOAMI)/g' docker/build/passwd && sed -i 's/USERID/$(USERID)/g' docker/build/passwd
	docker run --rm -u $(USERID):$(USERID) -v $(PWD)/docker/build/passwd:/etc/passwd:ro -v $(PWD)/app:/app $(PROJECT)-$(ENV):build
	rm -rf app/.config/ app/.npm/

code-test:
	docker-compose up -d && sh test/wait.sh
	newman run test/data/webapi_test.postman_test_run --reporters cli
	docker-compose down

image-push:
	echo "nublado951" | docker login -u "$(OWNER)" --password-stdin
	docker tag $(PROJECT)-$(ENV):app $(OWNER)/$(PROJECT)-$(ENV):latest && docker push $(OWNER)/$(PROJECT)-$(ENV):latest
	docker tag $(PROJECT)-$(ENV):app $(OWNER)/$(PROJECT)-$(ENV):$(VERSION) && docker push $(OWNER)/$(PROJECT)-$(ENV):$(VERSION)

k8s-create-cluster:
	eksctl create cluster \
	  --name $(PROJECT)-$(ENV) \
	  --region $(AWS_REGION) \
	  --zones=$(AWS_ZONE_A),$(AWS_ZONE_B) \
	  --version 1.14 \
	  --node-type t3a.medium \
	  --nodes 2 \
	  --auto-kubeconfig

k8s-ingress:
	kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
	kubectl --kubeconfig $(KUBECONFIG) apply -f k8s/service-l7.yaml
	kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/patch-configmap-l7.yaml

k8s-create-service:
	kubectl --kubeconfig $(KUBECONFIG) apply -f k8s/create/deployment.yaml
	export IMAGE=$(OWNER)/$(PROJECT)-$(ENV):latest && envsubst < k8s/service.yaml | kubectl --kubeconfig $(KUBECONFIG) apply -f -
	kubectl --kubeconfig $(KUBECONFIG) apply -f k8s/create/ingress.yaml

k8s-create-update:
	kubectl --kubeconfig $(KUBECONFIG) set image deployments/api api=$(OWNER)/$(PROJECT)-$(ENV):latest