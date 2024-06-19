# healthz image
FROM ghcr.io/binkhq/healthz:2022-03-11T125439Z as healthz

# Debian builder image
FROM docker.io/library/debian:bookworm-20240612 AS builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install packages
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update \
  && \
  apt-get install -y --no-install-recommends \
    build-essential=12.9 \
    ca-certificates=20230311 \
    curl=7.88.1-10+deb12u5 \
  && \
  apt-get clean \
  && \
  rm -rf /var/lib/apt/lists/*

# Build cfssl
FROM builder AS cfssl-builder

RUN \
  curl https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssl_1.6.4_linux_amd64 --location --output /usr/local/bin/cfssl \
  && \
  chmod +x \
    /usr/local/bin/cfssl

# Build cfssljson
FROM builder AS cfssljson-builder

RUN \
  curl https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssljson_1.6.4_linux_amd64 --location --output /usr/local/bin/cfssljson \
  && \
  chmod +x \
    /usr/local/bin/cfssljson

# Build dumb-init
FROM builder as dumb-init-builder

RUN \
  curl "https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_$(uname -m)" --location --output /usr/local/bin/dumb-init \
  && \
  chmod +x \
    /usr/local/bin/dumb-init

# Build gosu
FROM builder as gosu-builder

RUN \
  curl https://github.com/tianon/gosu/releases/download/1.17/gosu-amd64 --location --output /usr/local/bin/gosu \
  && \
  chmod +x \
    /usr/local/bin/gosu

# Build restic
FROM builder AS restic-builder

RUN \
  curl https://github.com/restic/restic/releases/download/v0.16.4/restic_0.16.4_linux_amd64.bz2 --location --output /usr/local/src/restic.bz2 \
  && \
  bzip2 --decompress --keep /usr/local/src/restic.bz2 \
  && \
  mv /usr/local/src/restic /usr/local/bin/restic \
  && \
  chmod +x \
    /usr/local/bin/restic

# Build mktorrent
FROM builder AS mktorrent-builder

RUN \
  mkdir -p /usr/local/src/mktorrent \
  && \
  curl https://github.com/pobrn/mktorrent/archive/master.tar.gz --location --output /usr/local/src/mktorrent.tar.gz \
  && \
  tar --gzip --extract --verbose --directory /usr/local/src/mktorrent --strip-components=1 --file /usr/local/src/mktorrent.tar.gz \
  && \
  make install --directory /usr/local/src/mktorrent

# Build whatmp3
FROM builder as whatmp3-builder

RUN \
  mkdir -p /usr/local/src/whatmp3 \
  && \
  curl https://github.com/RecursiveForest/whatmp3/archive/master.tar.gz --location --output /usr/local/src/whatmp3.tar.gz \
  && \
  tar --gzip --extract --verbose --directory /usr/local/src/whatmp3 --strip-components=1 --file /usr/local/src/whatmp3.tar.gz \
  && \
  cp /usr/local/src/whatmp3/whatmp3.py /usr/local/bin/whatmp3

# Build yacron
FROM builder as yacron-builder

RUN \
  curl "https://github.com/gjcarneiro/yacron/releases/download/0.19.0/yacron-0.19.0-$(uname -m)-unknown-linux-gnu" --location --output /usr/local/bin/yacron \
  && \
  chmod +x \
    /usr/local/bin/yacron

# Build yq
FROM builder as yq-builder

RUN \
  curl https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 --location --output /usr/local/bin/yq \
  && \
  chmod +x \
    /usr/local/bin/yq

# Build yt-dlp
FROM builder as yt-dlp-builder

RUN \
  curl https://github.com/yt-dlp/yt-dlp/releases/download/2023.11.16/yt-dlp_linux --location --output /usr/local/bin/yt-dlp \
  && \
  chmod +x \
    /usr/local/bin/yt-dlp

# Main image
FROM docker.io/library/debian:bookworm-20240612
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

#FIXME: mdns-scan not available in arm64 so removed from apt-get install
# Install packages
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update \
  && \
  apt-get install -y --no-install-recommends \
    apt-utils=2.6.1 \
    ca-certificates=20230311 \
    curl=7.88.1-10+deb12u5 \
    dnsutils=1:9.18.19-1~deb12u1 \
    fio=3.33-3 \
    flac=1.4.2+ds-2 \
    git=1:2.39.2-1.1 \
    gnupg=2.2.40-1.1 \
    gnupg1=1.4.23-1.1+b1 \
    gnupg2=2.2.40-1.1 \
    iperf3=3.12-1+deb12u1 \
    jq=1.6-2.1 \
    lame=3.100-6 \
    librsvg2-bin=2.54.7+dfsg-1~deb12u1 \
    libxml2-utils=2.9.14+dfsg-1.3~deb12u1 \
    make=4.3-4.1 \
    # mdns-scan=0.5-5+b1 \
    moreutils=0.67-1 \
    mtr=0.95-1 \
    musl=1.2.3-1 \
    nano=7.2-1 \
    netcat-traditional=1.10-47 \
    openssh-client=1:9.2p1-2+deb12u2 \
    procps=2:4.0.2-3 \
    python3-pip=23.0.1+dfsg-1 \
    python3-setuptools=66.1.1-1 \
    rclone=1.60.1+dfsg-2+b5 \
    rename=2.01-1 \
    rsync=3.2.7-1 \
    sqlite3=3.40.1-2 \
    traceroute=1:2.1.2-1 \
    tree=2.1.0-1 \
    unzip=6.0-28 \
    usbutils=1:014-1+deb12u1 \
    xz-utils=5.4.1-0.2 \
  && \
  apt-get clean \
  && \
  rm -rf /var/lib/apt/lists/*

# Install confd
RUN \
  if [ "$(uname -m)" = "x86_64" ]; then \
    curl https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64 --location --output /usr/local/bin/confd \
  ; fi \
  && \
  if [ "$(uname -m)" = "aarch64" ]; then \
    curl https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-arm64 --location --output /usr/local/bin/confd \
  ; fi \
  && \
  chmod +x \
    /usr/local/bin/confd

# Copy from build images
COPY --from=healthz /healthz /usr/local/bin/healthz
COPY --from=cfssl-builder /usr/local/bin/cfssl /usr/local/bin/cfssl
COPY --from=cfssljson-builder /usr/local/bin/cfssljson /usr/local/bin/cfssljson
COPY --from=dumb-init-builder /usr/local/bin/dumb-init /usr/local/bin/dumb-init
COPY --from=gosu-builder /usr/local/bin/gosu /usr/local/bin/gosu
COPY --from=restic-builder /usr/local/bin/restic /usr/local/bin/restic
COPY --from=mktorrent-builder /usr/local/bin/mktorrent /usr/local/bin/mktorrent
COPY --from=whatmp3-builder /usr/local/bin/whatmp3 /usr/local/bin/whatmp3
COPY --from=yacron-builder /usr/local/bin/yacron /usr/local/bin/yacron
COPY --from=yq-builder /usr/local/bin/yq /usr/local/bin/yq
COPY --from=yt-dlp-builder /usr/local/bin/yt-dlp /usr/local/bin/yt-dlp

# Configure user
ENV PUID=0 \
    PGID=0

RUN groupadd -g 1000 -r    abc && \
    useradd  -u 1000 -r -g abc abc

# Configure entrypoint
COPY rootfs /
ENTRYPOINT ["/usr/local/bin/dumb-init", "-v", "--", "entrypoint.sh"]
CMD ["healthz"]
