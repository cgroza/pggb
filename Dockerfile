FROM debian:bullseye-slim AS binary

LABEL authors="Erik Garrison, Simon Heumos, Andrea Guarracino"
LABEL description="Preliminary docker image containing all requirements for pggb pipeline"
LABEL base_image="debian:bullseye-slim"
LABEL software="pggb"
LABEL about.home="https://github.com/pangenome/pggb"
LABEL about.license="SPDX:MIT"

# odgi's dependencies
RUN apt-get update \
    && apt-get install -y \
                       git \
                       bash \
                       cmake \
                       make \
                       g++ \
                       python3-dev \
                       bc \
                       libatomic-ops-dev \
                       autoconf \
                       libgsl-dev \
                       zlib1g-dev \
                       libzstd-dev \
                       libjemalloc-dev \
                       build-essential \
                       time \
                       curl \
                       pigz
                        
RUN git clone --recursive https://github.com/ekg/wfmash \
    && cd wfmash \
    && git pull \
    && git checkout 261bb9a3c56d813f81b92d82183f7e2936c8a016 \
    && git submodule update --init --recursive \
    && sed -i 's/-mcx16 //g' CMakeLists.txt \
    && sed -i 's/-march=native //g' CMakeLists.txt \
    && sed -i 's/-mcx16 //g' src/common/wflign/CMakeLists.txt \
    && sed -i 's/-march=native //g' src/common/wflign/CMakeLists.txt \
    && sed -i 's/-mcx16 //g' src/common/wflign/deps/WFAv2/CMakeLists.txt \
    && sed -i 's/-march=native //g' src/common/wflign/deps/WFAv2/CMakeLists.txt \
    && sed -i 's/-mcx16 //g' src/common/wflign/deps/wflambdav2/CMakeLists.txt \
    && sed -i 's/-march=native //g' src/common/wflign/deps/wflambdav2/CMakeLists.txt \
    && cmake -H. -Bbuild && cmake --build build -- -j $(nproc) \
    && cp build/bin/wfmash /usr/local/bin/wfmash \
    && cd ../

RUN git clone --recursive https://github.com/ekg/seqwish \
    && cd seqwish \
    && git pull \
    && git checkout 63fb48bfeb7504dab39966a0acc82a423f2207b2 \
    && git submodule update --init --recursive \
    && cmake -H. -Bbuild && cmake --build build -- -j $(nproc) \
    && cp bin/seqwish /usr/local/bin/seqwish \
    && cd ../

RUN git clone --recursive https://github.com/ekg/smoothxg \
    && cd smoothxg \
    && git pull \
    && git checkout a952fe07933d657cc070c954fb197c37e68e45e4 \
    && git submodule update --init --recursive \
    && sed -i 's/-march=native/-march=haswell/g' deps/abPOA/CMakeLists.txt \
    && sed -i 's/-mcx16 //g' deps/WFA/CMakeLists.txt \
    && sed -i 's/-march=native //g' deps/WFA/CMakeLists.txt \
    && cmake -H. -Bbuild && cmake --build build -- -j $(nproc) \
    && cp bin/smoothxg /usr/local/bin/smoothxg \
    && cp deps/odgi/bin/odgi /usr/local/bin/odgi

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo --help

RUN git clone https://github.com/marschall-lab/GFAffix.git \
    && cd GFAffix \
    && git pull \
    && git checkout b75302b \
    && cargo install --force --path . && mv /root/.cargo/bin/gfaffix /usr/local/bin/gfaffix

RUN apt-get update && apt-get install -y pip && pip install multiqc

RUN apt-get install wget && wget http://hypervolu.me/~erik/vg/vg-03efd3b.gz && zcat vg-03efd3b.gz >vg && chmod +x vg && cp vg /usr/local/bin/vg

COPY pggb /usr/local/bin/pggb
RUN chmod 777 /usr/local/bin/pggb

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
