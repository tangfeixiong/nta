# Inspired from https://github.com/philips/grpc-gateway-example
GOCMD := $(shell which go)
GOBIN_PATH := $(shell $(GOCMD) env GOBIN)
ifeq ($(GOBIN_PATH),)
    GOBIN_PATH := ${HOME}/go/bin
endif
GOPATH_PRJ ?= /Users/fanhongling/Downloads/workspace
GOPATH_DEF ?= /home/vagrant/go
ifeq (,$(wildcard $(GOBIN_PATH)/go-bindata))
  gobindatapkg := github.com/jteeuwen/go-bindata
  ifeq (,$(GOPATH_DEF)/src/$(gobindatapkg))
	$(info get go-bindata project into $(GOPATH_DEF) and build into $(GOBIN_PATH)...)
	$($(GOCMD) get $(gobindatapkg)/...
  endif
  $(info install go-bindata bin in $(GOBIN_PATH)...)
  $(shell GOPATH=$(GOPATH_DEF) GOBIN=$(GOBIN_PATH) $(GOCMD) install github.com/jteeuwen/go-bindata/go-bindata)
endif

KUBERNETES_PATH ?= /Users/fanhongling/go/src

IMG_NS?=docker.io/tangfeixiong
IMG_REPO?=nta
IMG_TAG?=0.1-k8sec
GIT_COMMIT=$(shell date +%y%m%d%H%M)-git$(shell git rev-parse --short=7 HEAD)
REGISTRY_HOST?=172.17.4.50:5000

.PHONY: all protoc-grpc protoc-api protoc-cadvisor

all: protoc-grpc gen-statik go-bindata docker-push

protoc-grpc: protoc-api
	@if [ -f "$(GOBIN_PATH)/protoc-gen-gogo" ]; then \
	  echo "Found protoc-gen-gogo in $(GOBIN_PATH)"; \
	  export PATH=$(GOBIN_PATH):${PATH}; \
	fi
	@PATH=$(GOBIN_PATH):$$PATH protoc -I/usr/local/include -I. \
		-Ivendor/github.com/grpc-ecosystem/grpc-gateway/ \
		-Ivendor/github.com/gogo/googleapis/ \
		-Ivendor/ \
		-I${GOPATH_PRJ}/src \
		-I${GOPATHD}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		--gogo_out=\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mgoogle/api/annotations.proto=github.com/gogo/googleapis/google/api,\
Mpb/moby/moby.proto=github.com/tangfeixiong/go-to-docker/pb/moby,\
Mpb/moby/container/container.proto=github.com/tangfeixiong/go-to-docker/pb/moby/container,\
Mpb/moby/network/network.proto=github.com/tangfeixiong/go-to-docker/pb/moby/network,\
Mpb/moby/filters/filters.proto=github.com/tangfeixiong/go-to-docker/pb/moby/filters,\
Mpb/k8sec/cadvisor/v1.proto=github.com/tangfeixiong/go-to-kubernetes/pb/k8sec/cadvisor,\
plugins=grpc:. \
		pb/k8sec/service.proto
	@PATH=$(GOBIN_PATH):$$PATH protoc -I/usr/local/include -I. \
		-Ivendor/github.com/grpc-ecosystem/grpc-gateway/ \
		-Ivendor/github.com/gogo/googleapis/ \
		-Ivendor/ \
		-I${GOPATH_PRJ}/src \
		-I${GOPATHD}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		--grpc-gateway_out=\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mgoogle/api/annotations.proto=github.com/gogo/googleapis/google/api,\
Mpb/moby/moby.proto=github.com/tangfeixiong/go-to-docker/pb/moby,\
Mpb/moby/container/container.proto=github.com/tangfeixiong/go-to-docker/pb/moby/container,\
Mpb/moby/network/network.proto=github.com/tangfeixiong/go-to-docker/pb/moby/network,\
Mpb/moby/filters/filters.proto=github.com/tangfeixiong/go-to-docker/pb/moby/filters,\
Mpb/k8sec/cadvisor/v1.proto=github.com/tangfeixiong/go-to-kubernetes/pb/k8sec/cadvisor,\
logtostderr=true:. \
		pb/k8sec/service.proto
	@PATH=$(GOBIN_PATH):$$PATH protoc -I/usr/local/include -I. \
		-Ivendor/github.com/grpc-ecosystem/grpc-gateway \
		-Ivendor/github.com/gogo/googleapis \
		-Ivendor/ \
		-I${GOPATH_PRJ}/src \
		-I${GOPATHD}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		--swagger_out=\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mgoogle/api/annotations.proto=github.com/gogo/googleapis/google/api,\
Mpb/moby/moby.proto=github.com/tangfeixiong/go-to-docker/pb/moby,\
Mpb/moby/container/container.proto=github.com/tangfeixiong/go-to-docker/pb/moby/container,\
Mpb/moby/network/network.proto=github.com/tangfeixiong/go-to-docker/pb/moby/network,\
Mpb/moby/filters/filters.proto=github.com/tangfeixiong/go-to-docker/pb/moby/filters,\
Mpb/k8sec/cadvisor/v1.proto=github.com/tangfeixiong/go-to-kubernetes/pb/k8sec/cadvisor,\
logtostderr=true:. \
		pb/k8sec/service.proto
	
	# Workaround for https://github.com/grpc-ecosystem/grpc-gateway/issues/229.
	sed -i.bak "s/empty.Empty/types.Empty/g" pb/k8sec/service.pb.gw.go && rm pb/k8sec/service.pb.gw.go.bak

	go generate ./pb/k8sec

protoc-api: protoc-cadvisor  protoc-kubernetes protoc-cni
	@if [ -f "$(GOBIN_PATH)/protoc-gen-gogo" ]; then \
	  echo "Found protoc-gen-gogo in $(GOBIN_PATH)"; \
	  export PATH=$(GOBIN_PATH):${PATH}; \
	fi
	@PATH=$(GOBIN_PATH):$$PATH protoc -I/usr/local/include -I. \
		-Ivendor/github.com/grpc-ecosystem/grpc-gateway \
		-Ivendor/github.com/gogo/googleapis \
		-Ivendor/ \
		-I${GOPATH_PRJ}/src \
		-I${GOPATH_DEF}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		-I${KUBERNETES_PATH} \
		--gogo_out=Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mk8s.io/api/core/v1/generated.proto=k8s.io/api/core/v1,\
Mk8s.io/api/apps/v1/generated.proto=k8s.io/api/apps/v1,\
Mpb/k8sec/cadvisor/v1.proto=github.com/tangfeixiong/go-to-kubernetes/pb/k8sec/cadvisor,\
Mpb/k8sec/cni/api.proto=github.com/tangfeixiong/go-to-kubernetes/pb/k8sec/cni,\
Mpb/k8sec/kubernetes/info.proto=github.com/tangfeixiong/go-to-kubernetes/pb/k8sec/kubernetes,\
Mpb/k8sec/collect.proto=github.com/tangfeixiong/go-to-kubernetes/pb/k8sec,\
Mpb/k8sec/network.proto=github.com/tangfeixiong/go-to-kubernetes/pb/k8sec:. \
        pb/k8sec/network.proto pb/k8sec/collect.proto

protoc-cadvisor:
	@if [ -f "$(GOBIN_PATH)/protoc-gen-gogo" ]; then \
	  echo "Found protoc-gen-gogo in $(GOBIN_PATH)"; \
	  export PATH=$(GOBIN_PATH):${PATH}; \
	fi
	@PATH=$(GOBIN_PATH):$$PATH protoc -I/usr/local/include -I. \
		-Ivendor/github.com/grpc-ecosystem/grpc-gateway \
		-Ivendor/github.com/gogo/googleapis \
		-Ivendor/ \
		-I${GOPATH_PRJ}/src \
		-I${GOPATH_DEF}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		--gogo_out=Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mpb/k8sec/cadvisor/v1.proto=github.com/tangfeixiong/go-to-kubernetes/pb/k8sec/cadvisor:. \
        pb/k8sec/cadvisor/v1.proto

protoc-kubernetes:
	@if [ -f "$(GOBIN_PATH)/protoc-gen-gogo" ]; then \
	  echo "Found protoc-gen-gogo in $(GOBIN_PATH)"; \
	  export PATH=$(GOBIN_PATH):${PATH}; \
	fi
	@PATH=$(GOBIN_PATH)::$$PATH protoc -I/usr/local/include -I. \
		-Ivendor/github.com/grpc-ecosystem/grpc-gateway \
		-Ivendor/github.com/gogo/googleapis \
		-Ivendor/ \
		-I${GOPATH_PRJ}/src \
		-I${GOPATHD}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		-I${KUBERNETES_PATH} \
		--gogo_out=Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mk8s.io/apimachinery/pkg/apis/meta/v1/generated.proto=k8s.io/apimachinery/pkg/apis/meta/v1,\
Mk8s.io/api/core/v1/generated.proto=k8s.io/api/core/v1,\
Mk8s.io/api/apps/v1/generated.proto=k8s.io/api/apps/v1,\
Mpb/k8sec/kubernetes/info.proto=github.com/tangfeixiong/go-to-kubernetes/pb/k8sec/kubernetes:. \
        pb/k8sec/kubernetes/info.proto

protoc-cni:
	@if [ -f "$(GOBIN_PATH)/protoc-gen-gogo" ]; then \
	  echo "Found protoc-gen-gogo in $(GOBIN_PATH)"; \
	  export PATH=$(GOBIN_PATH):${PATH}; \
	fi
	@PATH=$(GOBIN_PATH)::$$PATH protoc -I/usr/local/include -I. \
		-Ivendor/github.com/grpc-ecosystem/grpc-gateway \
		-Ivendor/github.com/gogo/googleapis \
		-Ivendor/ \
		-I${GOPATH_PRJ}/src \
		-I${GOPATHD}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		--gogo_out=Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/any.proto=github.com/gogo/protobuf/types,\
Mpb/k8sec/cni/api.proto=github.com/tangfeixiong/go-to-kubernetes/pb/k8sec/cni:. \
        pb/k8sec/cni/api.proto

protoc-todo:
	protoc -I/usr/local/include -I. \
		-Ivendor/github.com/grpc-ecosystem/grpc-gateway \
		-Ivendor/github.com/gogo/googleapis \
		-Ivendor/ \
		-I${GOPATH_PRJ}/src \
		-I${GOPATHD}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		--gogo_out=Mgoogle/protobuf/timestamp.proto=github.com/golang/protobuf/ptypes/timestamp,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mpb/moby/network/network.proto=github.com/tangfeixiong/go-to-docker/pb/moby/network:. \
        pb/moby/network/network.proto
	protoc -I/usr/local/include -I. \
		-Ivendor/github.com/grpc-ecosystem/grpc-gateway \
		-Ivendor/github.com/gogo/googleapis \
		-Ivendor/ \
		-I${GOPATH_PRJ}/src \
		-I${GOPATHD}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		--gogo_out=Mgoogle/protobuf/timestamp.proto=github.com/golang/protobuf/ptypes/timestamp,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mpb/moby/units/units.proto=github.com/tangfeixiong/go-to-docker/pb/moby/units:. \
        pb/moby/units/units.proto
	protoc -I/usr/local/include -I. \
		-Ivendor/github.com/grpc-ecosystem/grpc-gateway \
		-Ivendor/github.com/gogo/googleapis \
		-Ivendor/ \
		-I${GOPATH_PRJ}/src \
		-I${GOPATHD}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		--gogo_out=Mgoogle/protobuf/timestamp.proto=github.com/golang/protobuf/ptypes/timestamp,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mpb/moby/blkiodev/blkiodev.proto=github.com/tangfeixiong/go-to-docker/pb/moby/blkiodev,\
Mpb/moby/container/container.proto=github.com/tangfeixiong/go-to-docker/pb/moby/container,\
Mpb/moby/filters/filters.proto=github.com/tangfeixiong/go-to-docker/pb/moby/filters,\
Mpb/moby/mount/mount.proto=github.com/tangfeixiong/go-to-docker/pb/moby/mount,\
Mpb/moby/nat/nat.proto=github.com/tangfeixiong/go-to-docker/pb/moby/nat,\
Mpb/moby/network/network.proto=github.com/tangfeixiong/go-to-docker/pb/moby/network,\
Mpb/moby/units/units.proto=github.com/tangfeixiong/go-to-docker/pb/moby/units:. \
        pb/moby/container/container.proto
	protoc -I/usr/local/include -I. \
		-Ivendor/github.com/grpc-ecosystem/grpc-gateway \
		-Ivendor/github.com/gogo/googleapis \
		-Ivendor/ \
		-I${GOPATH_PRJ}/src \
		-I${GOPATHD}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		--gogo_out=Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mpb/moby/moby.proto=github.com/tangfeixiong/go-to-docker/pb/moby,\
Mpb/moby/blkiodev/blkiodev.proto=github.com/tangfeixiong/go-to-docker/pb/moby/blkiodev,\
Mpb/moby/container/container.proto=github.com/tangfeixiong/go-to-docker/pb/moby/container,\
Mpb/moby/filters/filters.proto=github.com/tangfeixiong/go-to-docker/pb/moby/filters,\
Mpb/moby/mount/mount.proto=github.com/tangfeixiong/go-to-docker/pb/moby/mount,\
Mpb/moby/nat/nat.proto=github.com/tangfeixiong/go-to-docker/pb/moby/nat,\
Mpb/moby/network/network.proto=github.com/tangfeixiong/go-to-docker/pb/moby/network,\
Mpb/moby/units/units.proto=github.com/tangfeixiong/go-to-docker/pb/moby/units:. \
        pb/moby/moby.proto

.PHONY: gen-statik go-bindata-dockerfile go-bindata-openapi

gen-statik:
	@if [[ ! -f $GOBIN/statik ]]; then \
		go install ./vendor/github.com/rakyll/statik; \
	fi
	#@cp ./pb/service.swagger.json ./third_party/OpenAPI/
	@go generate ./pkg/ui

go-bindata-dockerfile:
	$(eval gobin:=$(shell go env GOBIN))
	@if [[ ! -f $(gobin)/go-bindata ]]; then \
	    GOPATH=$(GOPATH_PRJ) $(GOCMD) install ./vendor/github.com/jteeuwen/go-bindata/...; \
	fi
	@pkg=artifact; src=template/...; output_file=pkg/api/$${pkg}/artifact_file.go; \
		go-bindata -nocompress -o $${output_file} -prefix $${PWD} -pkg $${pkg} $${src}

go-bindata-openapi:
	@pkg=openapi; src=third_party/OpenAPI/...; output_file=pkg/ui/$${pkg}/gobindatafile.go; \
		$(GOBIN_PATH)/go-bindata -nocompress -o $${output_file} -prefix $${PWD} -pkg $${pkg} $${src}

go-bindata-swagger:
	$(eval gobin:=$(shell go env GOBIN))
	@if [[ ! -f $(gobin)/go-bindata ]]; then \
		go install ./vendor/github.com/jteeuwen/go-bindata/...; \
	fi
	@pkg=swagger; src=third_party/swagger/...; output_file=pkg/ui/data/$${pkg}/datafile.go; \
		go-bindata -nocompress -o $${output_file} -prefix $${PWD} -pkg $${pkg} $${src}

.PHONY: go-install go-build go-clean-modcache clean

GOBUILD_EXTRA_OPT=
GOBUILD_ENV_VAR=GOPROXY=https://goproxy.cn
go-install:
	$(GOBUILD_ENV_VAR) go install -i -v $(GOBUILD_EXTRA_OPT) ./

go-build:
	#@CGO_ENABLED=0 go build -a -v -o ./bin/k8sec --installsuffix cgo -ldflags "-s" ./
	@CGO_ENABLED=0 go build -v -o ./bin/k8sec -tags netgo -installsuffix netgo -ldflags "-s" ./

go-cleanmod:
	# Issue: https://github.com/golang/go/issues/27215
	# go get golang.org/dl/gotip && gotip download is a handy way to try with the latest from Go tip.
	# https://github.com/golang/go/issues/29363
	# https://github.com/sql-machine-learning/sqlflow/issues/1741
	go clean -modcache
    
clean:
	go clean -i

.PHONY: docker-build docker-push docker-cgo docker-run

docker-build: go-build
	docker build --force-rm --no-cache -t $(IMG_NS)/$(IMG_REPO):$(IMG_TAG) ./

docker-push: docker-build
	docker push $(IMG_NS)/$(IMG_REPO):$(IMG_TAG)

docker-cgo:
	go build -v -a -o ./bin/gotodocker ./
	docker build -t $(IMG_NS)/$(IMG_REPO):$(IMG_TAG)-$(GIT_COMMIT) -f Dockerfile.cgo ./
	docker push $(IMG_NS)/$(IMG_REPO):$(IMG_TAG)

docker-run:
	$(info $(shell ./bootstrap.sh $(REGISTRY_HOST) "/etc/docker/certs.d/$(REGISTRY_HOST)/ca.crt"))

.PHONY: gotip serve-wasm

gotip:
	go get -u golang.org/dl/gotip
	$(GOBIN_PATH)/gotip download
	
serve-wasm:
	$(MAKE) --directory=wasm/k8sec-agent serve-wasm GOVER=""