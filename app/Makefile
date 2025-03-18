.PHONY: install build build-docker test all clean

all: install build test build-docker

build:
	go build ./...

build-docker:
	docker build --progress=plain -t go-echo-api .

install:
	go install -v ./...

fmt:
	go fmt ./...

lint: fmt
	golangci-lint run

run: fmt
	go run ./main.go

run-docker:
	docker run -it -p 8080:8080 go-echo-api:latest

test:
	go test ./...

clean:
	go clean ./...
