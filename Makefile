UNAME := $(shell uname)
ifeq ($(UNAME), Darwin)
	DHOST := $(shell echo $$(docker-machine ip))
else
	DHOST := 127.0.0.1
endif

all: get-deps build

.PHONY: build
build:
	go build ./...

.PHONY: get-deps
get-deps:
	go get -v ./...

.PHONY: test
test: get-deps lint-check docs-check check

.PHONY: check
check:
	go test -v -race -cover ./...

.PHONY: lint-check
lint-check:
	golangci-lint run

.PHONY: fmt
fmt:
	@go fmt ./... | awk '{ print "Please run go fmt"; exit 1 }'

.PHONY: docker-test
docker-test:
	docker run -d -p 5432:5432 --name=pgstore_test_1 postgres:9.4
	@echo "Ugly hack: Sleeping for 75 secs to give the Postgres container time to come up..."
	sleep 75
	@echo "Waking up - let's do this!"
	docker run --rm --link pgstore_test_1:postgres postgres:9.4 psql -c 'create database test;' -U postgres -h postgres
	PGSTORE_TEST_CONN="postgres://postgres@$(DHOST):5432/test?sslmode=disable" make test
	docker kill pgstore_test_1
	docker rm pgstore_test_1

.PHONY: docker-clean
docker-clean:
	-docker kill pgstore_test_1
	-docker rm pgstore_test_1

.PHONY: docs-dep
	which embedmd > /dev/null || go get github.com/campoy/embedmd

.PHONY: docs-check
docs-check: docs-dep
	@echo "Checking if docs are generated, if this fails, run 'make docs'."
	embedmd README.md | diff README.md -

.PHONY: docs
docs: docs-dep
	embedmd -w README.md
