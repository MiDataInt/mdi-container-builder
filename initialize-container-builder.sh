#!/bin/bash

#---------------------------------------------------------------
# Script to set up an AWS Ubuntu instance for building Singularity images.
# Create a new EC2 instance, then run this script from an SSH command prompt.
#---------------------------------------------------------------
GO_VERSION=1.17.5 # https://go.dev/dl/
SINGULARITY_VERSION=v3.9.2 # https://github.com/sylabs/singularity/releases
#---------------------------------------------------------------

#---------------------------------------------------------------
# use sudo initially to install resources and configure server as root
#---------------------------------------------------------------

# update system
echo 
echo "updating operating system"
sudo apt-get update
sudo apt-get upgrade -y

# install miscellaneous tools
echo 
echo "install miscellaneous tools"
sudo apt-get install -y \
    git \
    build-essential \
    tree \
    nano \
    apache2-utils \
    dos2unix \
    nfs-common \
    make \
    binutils

# install Singularity
# see https://sylabs.io/guides/3.0/user-guide/installation.html
echo 
echo "install Singularity"
sudo apt-get install -y \
    libssl-dev \
    uuid-dev \
    libgpgme11-dev \
    squashfs-tools \
    libseccomp-dev \
    pkg-config
export VERSION=$GO_VERSION OS=linux ARCH=amd64 && \
    wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
    sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && \
    rm go$VERSION.$OS-$ARCH.tar.gz
echo 'export GOPATH=${HOME}/go' >> ~/.bashrc && \
    echo 'export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin' >> ~/.bashrc
source ~/.bashrc
go get -u github.com/golang/dep/cmd/dep
go get -d github.com/sylabs/singularity
export VERSION=$SINGULARITY_VERSION && \
    cd $GOPATH/src/github.com/sylabs/singularity && \
    git fetch && \
    git checkout $VERSION 

echo
echo ============================
pwd
ls -l
which mconfig
echo ============================

./mconfig && \
    make -C ./builddir && \
    sudo make -C ./builddir install

#####################
exit

# set server groups
echo 
echo "create mdi-edit group"
sudo groupadd mdi-edit
sudo usermod -a -G mdi-edit ubuntu

#---------------------------------------------------------------
# continue as user ubuntu (i.e., not sudo) to install mdi
#---------------------------------------------------------------

# clone the MDI installer
echo 
echo "clone MiDataInt/mdi"
cd ~
git clone https://github.com/MiDataInt/mdi.git

# install the MDI
echo 
echo "install the MDI frameworks"
cd mdi
./install.sh 1 # i.e., pipelines only installation

# validate and report success
echo
echo "installation summary"
singularity --version
echo
