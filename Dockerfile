FROM ubuntu:22.04

ARG UID=1000
ARG GID=1000

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Copenhagen

# Install gpg by itself as it needs recommended packages (at least dirmngr).
RUN deps='sudo curl bzip2 ca-certificates wget zip unzip tzdata flex bison graphviz make libc6-dev patch python3 python3-pip python3-virtualenv python3-build cmake git gcc g++ gcc-multilib g++-multilib libboost-log1.74.0 dos2unix ruby ruby-dev clang valgrind texlive-bibtex-extra default-jre nodejs python3-yaml gdb xz-utils pylint pigz gh' \
    && apt-get update --fix-missing \
    && apt-get install -y --no-install-recommends $deps \
    && apt-get install -y gpg \
    && rm -rf /var/lib/apt/lists/*

# CMake
ARG CMAKE_VERSION=3.23.5
ARG CMAKE_KEY=CBA23971357C2E6590D9EFD3EC8FEF3A7BFB4EDA
RUN gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "${CMAKE_KEY}" && \
    mkdir -p /tmp/cmake && \
    cd /tmp/cmake && \
    wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-SHA-256.txt && \
    wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz && \
    sha256sum --quiet -c --ignore-missing cmake-${CMAKE_VERSION}-SHA-256.txt && \
    wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-SHA-256.txt.asc && \
    gpg --verify cmake-${CMAKE_VERSION}-SHA-256.txt.asc cmake-${CMAKE_VERSION}-SHA-256.txt && \
    tar -xvf cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz -C /opt && \
    rm -rf /tmp/cmake

ENV PATH=/opt/cmake-${CMAKE_VERSION}-linux-x86_64/bin:$PATH

# Plantuml
ENV PLANTUML_JAR_PATH=/usr/local/share/plantuml/plantuml.jar
RUN mkdir -p /usr/local/share/plantuml \
  && curl -L https://github.com/plantuml/plantuml/releases/download/v1.2022.0/plantuml-1.2022.0.jar \
    --output ${PLANTUML_JAR_PATH} \
  && sha256sum ${PLANTUML_JAR_PATH} | grep '^f1070c42b20e6a38015e52c10821a9db13bedca6b5d5bc6a6192fcab6e612691 '

# Fetch and install Doxygen
ARG DOXYGEN_URL=https://github.com/doxygen/doxygen/archive/Release_1_10_0.zip
ARG DOXYGEN_SHA512=b05ee2a790a6a477914a3dff28594708ac7e00956a2960df96e7dfd353e1b93afc538d464e05b630540f17c8ade30772516df885f73ac766508718b36ae0ba99
RUN wget -q $DOXYGEN_URL -O /tmp/doxygen.zip \
    && echo "$DOXYGEN_SHA512 /tmp/doxygen.zip" | sha512sum -c --quiet \
    && cd /tmp/ \
    && unzip -q doxygen.zip \
    && cd /tmp/doxygen*/ \
    && mkdir build && cd build \
    && cmake .. \
    && N_CPU_CORES=`cat /proc/cpuinfo | grep processor | wc -l` \
    && make -j $N_CPU_CORES && make install \
    && rm -rf /tmp/doxygen*

# ARM GCC
RUN cd /tmp/ && \
    wget https://developer.arm.com/-/media/Files/downloads/gnu/12.3.rel1/binrel/arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-eabi.tar.xz && \
    wget https://developer.arm.com/-/media/Files/downloads/gnu/12.3.rel1/binrel/arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc && \
    sha256sum --check arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc && \
    tar xJf arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-eabi.tar.xz -C /opt && \
    rm arm-gnu-toolchain*

ENV PATH=/opt/arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-eabi/bin:$PATH

# GCOVR
RUN pip install gcovr==7.0

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN groupadd -g $GID -o build
RUN useradd -m -u $UID -g $GID -G sudo -p -o -s /bin/bash build
USER build
WORKDIR /sdk
