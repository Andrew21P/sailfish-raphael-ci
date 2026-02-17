FROM --platform=linux/amd64 ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies in stages for better error handling
RUN apt-get update && apt-get install -y --no-install-recommends \
    bc bison build-essential ccache curl flex \
    git gnupg gperf wget unzip zip openssh-client ca-certificates \
    libncurses5 libncurses5-dev libssl-dev \
    libxml2 libxml2-utils lzop rsync xsltproc \
    openjdk-11-jdk python3 vim nano \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Additional packages that may or may not exist
RUN apt-get update && apt-get install -y --no-install-recommends \
    g++-multilib gcc-multilib zlib1g-dev squashfs-tools \
    python-is-python3 imagemagick pngcrush \
    || true \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install repo tool
RUN mkdir -p /root/bin && \
    curl https://storage.googleapis.com/git-repo-downloads/repo > /root/bin/repo && \
    chmod a+x /root/bin/repo

ENV PATH="/root/bin:${PATH}"

# Git config
RUN git config --global user.email "build@local" && \
    git config --global user.name "Build Bot" && \
    git config --global color.ui false

# Set up ccache
ENV USE_CCACHE=1
ENV CCACHE_DIR=/ccache
ENV CCACHE_EXEC=/usr/bin/ccache

# Working directory
WORKDIR /halium

# Default command
CMD ["/bin/bash"]
