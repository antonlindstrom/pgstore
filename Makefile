all: get-deps build

.PHONY: build
build:
	go build ./...

.PHONY: get-deps
get-deps:
	go get -v ./...

.PHONY: test
test: get-deps metalint check

.PHONY: check
check:
	go test -v -race -cover ./...

.PHONY: metalint
metalint:
	which gometalinter > /dev/null || (go get github.com/alecthomas/gometalinter && gometalinter --install --update)
	gometalinter --cyclo-over=20 -e "struct field Id should be ID" --enable="gofmt -s" --enable=misspell --fast ./...

.PHONY: fmt
fmt:
	@go fmt ./... | awk '{ print "Please run go fmt"; exit 1 }'

.PHONY: docker-test
docker-test:
	docker run -d -p 5432:5432 --name=pgstore_test_1 postgres:9.4
	sleep 5
	docker run --rm --link pgstore_test_1:postgres postgres:9.4 psql -c 'create database test;' -U postgres -h postgres
	PGSTORE_TEST_CONN="postgres://postgres@127.0.0.1:5432/test?sslmode=disable" make check
	docker kill pgstore_test_1
	docker rm pgstore_test_1

.PHONY: docker-clean
docker-clean:
	-docker kill pgstore_test_1
	-docker rm pgstore_test_1
