FROM bitextor/bitextor:8.3

COPY cirrus-scripts /cirrus-scripts
WORKDIR /cirrus-scripts

RUN git submodule update --init env/src/preprocess/
RUN mkdir /cirrus-scripts/env/src/paracrawl/build && \
    cd /cirrus-scripts/env/src/paracrawl/build && \
    cmake .. && \
    make -j8 merge_sort && \
    cp bin/merge_sort /usr/local/bin/

COPY GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB /mkl-key.pub
RUN mkdir /etc/apt/keyrings
RUN gpg --dearmor -o /etc/apt/keyrings/mkl.gpg /mkl-key.pub && rm /mkl-key.pub
RUN echo "deb [signed-by=/etc/apt/keyrings/mkl.gpg] https://apt.repos.intel.com/mkl all main" > /etc/apt/sources.list.d/intel-mkl.list
RUN apt-get update && apt-get install -yy intel-mkl-64bit-2020.0-088

# Compile Marian CPU from Bergamot
RUN git clone https://github.com/browsermt/marian-dev /opt/marian-bergamot
WORKDIR /opt/marian-bergamot
RUN git checkout 2be8344fcf2776fb43a7376284067164674cbfaf
WORKDIR /opt/marian-bergamot/build
RUN cmake .. -DUSE_SENTENCEPIECE=on -DCOMPILE_CUDA=off -DUSE_FBGEMM=on
RUN make -j24

RUN pip uninstall -y tensorflow keras
RUN pip install tensorflow-rocm==2.12.1.600

RUN apt-get remove -yy intel-mkl-64bit-2020.0-088 build-essential && apt-get -yy autoremove && \
    rm -Rf /opt/marian-bergamot/build/src && \
    rm -Rf /opt/marian-bergamot/src && \
    rm -Rf /opt/marian-bergamot/build/local && \
    rm -Rf /opt/marian-bergamot/build/libmarian.a && \
    strip /opt/marian-bergamot/build/marian* && \
    strip /opt/marian-bergamot/build/spm*

RUN apt-get install -y locales
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

ENTRYPOINT ["/bin/bash"]
