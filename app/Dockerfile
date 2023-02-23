FROM golang:1.18 AS builder

RUN mkdir /app

COPY ./go.mod /app/
COPY ./go.sum /app/
COPY ./main.go /app/
WORKDIR /app

RUN go install
RUN go build main.go

RUN adduser go
RUN chown ./main go

USER go

EXPOSE 8000

CMD ["./main"]