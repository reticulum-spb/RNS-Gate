# Buildroot host environment for the RNS-Gate image.
# Buildroot must not run as root, so the build is dropped to an
# unprivileged user via gosu after the volume ownership is fixed.

FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        bash bc binutils build-essential bzip2 ca-certificates cpio \
        file findutils git gosu gzip libncurses-dev libssl-dev locales \
        make patch perl python3 rsync sed tar unzip wget which xz-utils \
    && localedef -i C -c -f UTF-8 C.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN groupadd -g 1000 br && useradd -m -u 1000 -g 1000 -s /bin/bash br

COPY entrypoint.sh build.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/build.sh

WORKDIR /build
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
