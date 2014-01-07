all: get-deps

get-deps:
	@go get -d -v ./...

format:
	@go fmt ./...
