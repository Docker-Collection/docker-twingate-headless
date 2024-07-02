FROM golang:1.22.4@sha256:3589439790974ec05491b66b656bf1048d0f50dd010a903463e3156ba1fc26de as pf

WORKDIR /build
ENV GO111MODULE=on
COPY main.go /build

RUN CGO_ENABLED=0 go build main.go && mv main pf

FROM bitnami/minideb:bullseye@sha256:cbbe87f660843df98ef0474addbfd03b4109442942035c59f8249079287cef8b

WORKDIR /app

RUN apt-get update && \
    apt-get install --no-install-recommends -y ca-certificates && \
    echo "deb [trusted=yes] https://packages.twingate.com/apt/ /" | tee /etc/apt/sources.list.d/twingate.list && \
    apt-get update -o Dir::Etc::sourcelist="sources.list.d/twingate.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" && \
    apt-get install --no-install-recommends -y twingate && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /app/
COPY --from=pf /build/pf /app/

ENTRYPOINT [ "/app/entrypoint.sh" ]