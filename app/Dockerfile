FROM golang:1.18 AS builder

RUN mkdir /app

COPY . /app/

WORKDIR /app

RUN go install
RUN go build main.go

# RUN ls -alh

#FROM golang:alpine AS runtime
# FROM bitnami/minideb:stretch AS runtime

#COPY --from=builder /app/main ./main

# RUN ls -alh

EXPOSE 8000

CMD ["./main"]