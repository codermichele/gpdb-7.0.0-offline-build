#!/bin/bash

apt-get update
apt-get install -y \
  bison \
  ccache \
  cmake \
  curl \
  flex \
  git\
  gcc \
  g++ \
  inetutils-ping \
  krb5-kdc \
  krb5-admin-server \
  libapr1-dev \
  libbz2-dev \
  libcurl4-gnutls-dev \
  libevent-dev \
  libkrb5-dev \
  libpam0g-dev\
  libperl-dev \
  libreadline-dev \
  libssl-dev \
  libxml2-dev \
  libyaml-dev \
  locales \
  net-tools \
  ninja-build \
  openssh-client \
  openssh-server \
  openssl \
  python3-dev \
  python3-psutil \
  python3-pip \
  python3-yaml \
  zlib1g-dev \
  pkg-config

cd /gpdb_src/zstd-1.5.5
make && make install

cd /gpdb_src/gp-xerces-3.1.2-p1
mkdir build
cd build
../configure --prefix=/usr/local
make -j8
make -j8 install

tee -a /etc/sysctl.conf << EOF
kernel.shmmax = 5000000000000
kernel.shmmni = 32768
kernel.shmall = 40000000000
kernel.sem = 1000 32768000 1000 32768
kernel.msgmnb = 1048576
kernel.msgmax = 1048576
kernel.msgmni = 32768

net.core.netdev_max_backlog = 80000
net.core.rmem_default = 2097152
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

vm.overcommit_memory = 2
vm.overcommit_ratio = 95
EOF

sysctl -p

mkdir -p /etc/security/limits.d
tee -a /etc/security/limits.d/90-greenplum.conf << EOF
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
EOF

ulimit -n 65536 65536
