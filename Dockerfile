FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        python3 \
        python3-pip \
        python3-venv \
        build-essential \
        autoconf \
        libtool \
        pkg-config \
        libssl-dev \
        curl \
        sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m openplc \
    && echo "openplc ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/openplc

USER openplc
WORKDIR /home/openplc

RUN git clone --depth 1 https://github.com/thiagoralves/OpenPLC_v3.git

WORKDIR /home/openplc/OpenPLC_v3
RUN ./install.sh linux

# Copy custom entrypoint that patches config.py and seeds REST API user
COPY --chown=openplc:openplc entrypoint.sh /home/openplc/OpenPLC_v3/entrypoint.sh
RUN chmod +x /home/openplc/OpenPLC_v3/entrypoint.sh

EXPOSE 8080
CMD ["/home/openplc/OpenPLC_v3/entrypoint.sh"]
