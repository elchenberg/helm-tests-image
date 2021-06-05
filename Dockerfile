FROM golang:1.16.5-buster@sha256:9d8f70f7f67e461ae75c148ee66394f4242f4b359c27222c31aeea1851c39d8f AS go

ENV GO111MODULE=on
RUN go get github.com/cloudflare/cloudflare-go/cmd/flarectl@v0.13.7

# lab
RUN git clone https://github.com/zaquestion/lab.git \
	&& cd lab \
	&& git checkout v0.17.2 \
	&& go install -ldflags "-X \"main.version=$(git  rev-parse --short=10 HEAD)\"" .

# final image
FROM ubuntu:21.04

# copy multistage artifacts
COPY --from=go /go/bin/flarectl /usr/local/bin/flarectl
COPY --from=go /go/bin/lab      /usr/local/bin/lab

# make curl bats dig git envsubst skopeo
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install make curl bats dnsutils git gettext skopeo -y

# velero
ENV VELERO_VERSION=v1.6.0
RUN curl -L --fail https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz \
        | tar -xzO velero-${VELERO_VERSION}-linux-amd64/velero \
        > /usr/bin/velero && \
    chmod +x /usr/bin/velero

# kubectl
ENV KUBECTL_VERSION=v1.21.1
RUN curl -L --silent --fail -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
RUN chmod +x /usr/local/bin/kubectl

# add lets encrypt stage cert
RUN curl --fail --silent -L -o /usr/local/share/ca-certificates/fakelerootx1.crt https://letsencrypt.org/certs/staging/letsencrypt-stg-int-r3.pem
RUN update-ca-certificates


WORKDIR /tests
