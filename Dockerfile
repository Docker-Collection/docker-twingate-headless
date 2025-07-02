FROM golang:1.24.4@sha256:20a022e5112a144aa7b7aeb3f22ebf2cdaefcc4aac0d64e8deeee8cdc18b9c0f as pf

WORKDIR /build
ENV GO111MODULE=on
COPY main.go /build

RUN CGO_ENABLED=0 go build main.go && mv main pf

FROM bitnami/minideb:bullseye@sha256:4108f06d508239244a88f56fa52c203aa470774dfa56853ae212456d100d00e4

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