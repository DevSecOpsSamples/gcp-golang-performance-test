FROM golang:1.18 AS builder

RUN mkdir /app

COPY ./go.mod /app/
COPY ./go.sum /app/
COPY ./main.go /app/

RUN adduser go

USER go

WORKDIR /app

RUN go install
RUN go build main.go

EXPOSE 8000

CMD ["./main"]