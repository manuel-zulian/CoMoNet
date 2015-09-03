#
# Dockerfile for building accumunet
#
FROM debian

# Install accumunet
RUN apt-get update && apt-get install -y git \
autoconf \
libtool \
build-essential \
libboost-all-dev \
libssl-dev \
libdb++-dev \
libminiupnpc-dev && apt-get clean
RUN git clone https://github.com/manuel-zulian/accumunet.git accumunet
RUN cd accumunet && \
    ./bootstrap.sh && \
    make -j 8

# Configure HOME directory
# and persist twister data directory as a volume
ENV HOME /root
VOLUME /root/.twister

# Run twisterd by default
ENTRYPOINT ["/accumunet/twisterd", "-rpcuser=user", "-rpcpassword=pwd", "-rpcallowip=172.17.42.1", "-htmldir=/accumunet/html"]
EXPOSE 28332
EXPOSE 28333
EXPOSE 29333
