FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN userdel -r ubuntu 2>/dev/null

ENV TZ=Europe/Copenhagen

# Install gpg by itself as it needs recommended packages (at least dirmngr).
RUN deps='sudo curl bzip2 ca-certificates wget zip unzip tzdata flex bison graphviz make libc6-dev patch python3 python3-pip python3-virtualenv python3-build cmake git gcc g++ gcc-multilib g++-multilib libboost-log1.74.0 dos2unix ruby ruby-dev clang valgrind texlive-bibtex-extra default-jre nodejs python3-yaml gdb xz-utils pylint pigz gh' \
    && apt-get update --fix-missing \
    && apt-get install -y --no-install-recommends $deps \
    && apt-get install -y gpg \
    gosu \
    bash-completion \
    gcc-arm-none-eabi \
    && rm -rf /var/lib/apt/lists/*

# Plantuml
ENV PLANTUML_JAR_PATH=/usr/local/share/plantuml/plantuml.jar
RUN mkdir -p /usr/local/share/plantuml \
  && curl -L https://github.com/plantuml/plantuml/releases/download/v1.2022.0/plantuml-1.2022.0.jar \
    --output ${PLANTUML_JAR_PATH} \
  && sha256sum ${PLANTUML_JAR_PATH} | grep '^f1070c42b20e6a38015e52c10821a9db13bedca6b5d5bc6a6192fcab6e612691 '

# Fetch and install Doxygen
ARG DOXYGEN_URL=https://github.com/doxygen/doxygen/releases/download/Release_1_15_0/doxygen-1.15.0.linux.bin.tar.gz
ARG DOXYGEN_SHA256=0ec2e5b2c3cd82b7106d19cb42d8466450730b8cb7a9e85af712be38bf4523a1
RUN wget -q $DOXYGEN_URL -O /tmp/doxygen.tar.gz \
    && echo "$DOXYGEN_SHA256 /tmp/doxygen.tar.gz" | sha256sum -c --quiet \
    && cd /tmp/ \
    && mkdir /opt/doxygen \
    && tar -xvf doxygen.tar.gz -C /opt/doxygen/ --strip-components=1 \
    && rm /tmp/doxygen*

ENV PATH=/opt/doxygen/bin:$PATH

# GCOVR and pyelftools
RUN pip install --break-system-packages gcovr==7.0 pyelftools==0.32 ecdsa

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 700 /usr/local/bin/entrypoint.sh

WORKDIR /sdk

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
