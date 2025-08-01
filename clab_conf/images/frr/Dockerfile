# ベースイメージの指定
FROM ubuntu:24.04

# 環境変数の設定
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# 必要な依存関係をインストール
RUN apt-get update
RUN apt-get install -y \
   git autoconf automake libtool make libreadline-dev texinfo \
   pkg-config libpam0g-dev libjson-c-dev bison flex \
   libc-ares-dev python3-dev python3-sphinx \
   install-info build-essential libsnmp-dev perl \
   protobuf-c-compiler libprotobuf-c-dev \
   libcap-dev libelf-dev libunwind-dev \
   cmake libpcre2-dev \
   libgrpc++-dev protobuf-compiler-grpc \
   vim iproute2 tcpdump iputils-ping net-tools traceroute tshark zip wget curl && \
   apt-get clean && rm -rf /var/lib/apt/lists/*

# libyangのビルドとインストール
RUN git clone https://github.com/CESNET/libyang.git && \
    cd libyang && \
    git checkout v2.1.128 && \
    mkdir build && cd build && \
    cmake --install-prefix /usr \
          -D CMAKE_BUILD_TYPE:String="Release" .. && \
    make -j $(nproc) && make install && \
    cd ~/..

# FRRユーザーとグループの作成
RUN groupadd -r -g 92 frr && \
    groupadd -r -g 85 frrvty && \
    adduser --system --ingroup frr --home /var/run/frr/ \
       --gecos "FRR suite" --shell /sbin/nologin frr && \
    usermod -a -G frrvty frr

# FRRのビルドとインストール
RUN git clone https://github.com/k1yoto/frr.git && \
    cd frr && \
    git checkout feature/isis-srv6-sid-mt && \
    ./bootstrap.sh && \
    ./configure \
        --prefix=/usr \
        --includedir=\${prefix}/include \
        --bindir=\${prefix}/bin \
        --sbindir=\${prefix}/lib/frr \
        --libdir=\${prefix}/lib/frr \
        --libexecdir=\${prefix}/lib/frr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-moduledir=\${prefix}/lib/frr/modules \
        --enable-configfile-mask=0640 \
        --enable-logfile-mask=0640 \
        --enable-snmp=agentx \
        --enable-multipath=64 \
        --enable-user=frr \
        --enable-group=frr \
        --enable-vty-group=frrvty \
        --with-pkg-git-version \
        --with-pkg-extra-version=-FRRP4 && \
    make -j $(nproc) && make install

# 必要なディレクトリと設定ファイルのインストール
RUN install -m 775 -o frr -g frr -d /var/log/frr && \
    install -m 775 -o frr -g frrvty -d /etc/frr && \
    install -m 640 -o frr -g frrvty /frr/tools/etc/frr/vtysh.conf /etc/frr/vtysh.conf && \
    install -m 640 -o frr -g frr /frr/tools/etc/frr/frr.conf /etc/frr/frr.conf && \
    install -m 640 -o frr -g frr /frr/tools/etc/frr/daemons.conf /etc/frr/daemons.conf && \
    install -m 640 -o frr -g frr /frr/tools/etc/frr/daemons /etc/frr/daemons && \
    install -m 640 -o frr -g frr /dev/null /etc/frr/zebra.conf && \
    install -m 640 -o frr -g frr /dev/null /etc/frr/bgpd.conf && \
    install -m 640 -o frr -g frr /dev/null /etc/frr/ospfd.conf && \
    install -m 640 -o frr -g frr /dev/null /etc/frr/ospf6d.conf && \
    install -m 640 -o frr -g frr /dev/null /etc/frr/isisd.conf && \
    install -m 640 -o frr -g frr /dev/null /etc/frr/ripd.conf && \
    install -m 640 -o frr -g frr /dev/null /etc/frr/ripngd.conf && \
    install -m 640 -o frr -g frr /dev/null /etc/frr/pimd.conf && \
    install -m 640 -o frr -g frr /dev/null /etc/frr/ldpd.conf && \
    install -m 640 -o frr -g frr /dev/null /etc/frr/nhrpd.conf

RUN echo include /usr/local/lib >> /etc/ld.so.conf && ldconfig

# 修正されたエントリーポイントスクリプトをコピー
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# エントリーポイントを設定
ENTRYPOINT ["/entrypoint.sh"]