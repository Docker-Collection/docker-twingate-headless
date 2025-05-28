FROM golang:1.24.3@sha256:4c0a1814a7c6c65ece28b3bfea14ee3cf83b5e80b81418453f0e9d5255a5d7b8 as pf

WORKDIR /build
ENV GO111MODULE=on
COPY main.go /build

RUN CGO_ENABLED=0 go build main.go && mv main pf

FROM bitnami/minideb:bullseye@sha256:e8a54472f371914b6b378b343a6e882f1e06ae65ffb9ec0f69c3cffaf9dddb57

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