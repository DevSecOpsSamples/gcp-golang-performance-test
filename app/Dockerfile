FROM golang:1.18 AS builder

RUN mkdir /app

COPY ./go* /app/

WORKDIR /app

RUN go install
RUN go build main.go

EXPOSE 8000

CMD ["./main"]