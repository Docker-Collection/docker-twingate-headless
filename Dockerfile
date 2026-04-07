FROM golang:1.26.1@sha256:5e69504bb541a36b859ee1c3daeb670b544b74b3dfd054aea934814e9107f6eb as pf

WORKDIR /build
ENV GO111MODULE=on
COPY main.go /build

RUN CGO_ENABLED=0 go build main.go && mv main pf

FROM bitnami/minideb:bullseye@sha256:052f09c4f692ba9dd5f3224332bd8d675ab0af5e27b3d284c1db6b3b6a9b67a0

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