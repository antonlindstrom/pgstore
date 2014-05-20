all: get-deps build

build:
	@go build pgstore.go

get-deps:
	@go get -d -v ./...

test:
	@go test ./...

format:
	@go fmt ./...
