FROM ubuntu:22.04

ARG UID=1000
ARG GID=1000

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Copenhagen

RUN deps='sudo curl bzip2 ca-certificates wget zip unzip tzdata flex bison graphviz make libc6-dev patch python3 python3-pip python3-virtualenv python3-build gcovr cmake git gcc g++ gcc-multilib g++-multilib libboost-log1.74.0 dos2unix ruby ruby-dev clang valgrind texlive-bibtex-extra default-jre nodejs python3-yaml gdb' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $deps \
    && rm -rf /var/lib/apt/lists/*

# Plantuml
ENV PLANTUML_JAR_PATH=/usr/local/share/plantuml/plantuml.jar
RUN mkdir -p /usr/local/share/plantuml \
  && curl -L https://github.com/plantuml/plantuml/releases/download/v1.2022.0/plantuml-1.2022.0.jar \
    --output ${PLANTUML_JAR_PATH} \
  && sha256sum ${PLANTUML_JAR_PATH} | grep '^f1070c42b20e6a38015e52c10821a9db13bedca6b5d5bc6a6192fcab6e612691 '

# Fetch and install Doxygen
ARG DOXYGEN_URL=https://github.com/doxygen/doxygen/archive/Release_1_9_4.zip
ARG DOXYGEN_SHA512=4bf5fde0a94e077f78673499152c4e2c5456d31f758bd5e3cf3fb8f1a90836b273739c5d655345068235f202be422790ed0bcbb95ecaa95f818e718322d60f55
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
RUN wget -O archive.tar.bz2 "https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2?rev=78196d3461ba4c9089a67b5f33edf82a&hash=D484B37FF37D6FC3597EBE2877FB666A41D5253B" && \
    echo 2383e4eb4ea23f248d33adc70dc3227e archive.tar.bz2 > /tmp/archive.md5 && md5sum -c /tmp/archive.md5 && rm /tmp/archive.md5 && \
    tar xf archive.tar.bz2 -C /opt && \
    rm archive.tar.bz2

ENV PATH=/opt/gcc-arm-none-eabi-10.3-2021.10/bin:$PATH

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN groupadd -g $GID -o build
RUN useradd -m -u $UID -g $GID -G sudo -p -o -s /bin/bash build
USER build
WORKDIR /z-wave
