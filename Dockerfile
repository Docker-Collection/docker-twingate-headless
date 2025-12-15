FROM golang:1.25.5@sha256:36b4f45d2874905b9e8573b783292629bcb346d0a70d8d7150b6df545234818f as pf

WORKDIR /build
ENV GO111MODULE=on
COPY main.go /build

RUN CGO_ENABLED=0 go build main.go && mv main pf

FROM bitnami/minideb:bullseye@sha256:4d0ab5d148f2b8a29383e8a24a2c32cad7c4cd0f0766dd240a286dc2a03f3647

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