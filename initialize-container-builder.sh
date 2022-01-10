#!/bin/bash

#---------------------------------------------------------------
# Script to set up an AWS Ubuntu instance for building Singularity images.
# Create a new EC2 instance, then run this script from an SSH command prompt.
#---------------------------------------------------------------
GO_VERSION=1.17.5          # https://go.dev/dl/
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
# see https://sylabs.io/guides/latest/user-guide/quick_start.html
echo 
echo "install additional tools required by Singularity"
sudo apt-get install -y \
    libseccomp-dev \
    pkg-config \
    squashfs-tools \
    cryptsetup
echo 
echo "install Go"
export VERSION=$GO_VERSION OS=linux ARCH=amd64 && \
    wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
    sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && \
    rm go$VERSION.$OS-$ARCH.tar.gz
echo 'export GOPATH=${HOME}/go' >> ~/.bashrc && \
    echo 'export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin' >> ~/.bashrc
export GOPATH=${HOME}/go # sourcing ~/.bashrc does not work
export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin
echo 
echo "install Singularity"
cd ~ # chose to use git clone rather than package download, either works
export VERSION=$SINGULARITY_VERSION && \
    git clone https://github.com/sylabs/singularity.git && \
    cd singularity && \
    git checkout $VERSION 
./mconfig && \
    make -C ./builddir && \
    sudo make -C ./builddir install

# set server groups
echo 
echo "create mdi-edit group"
sudo groupadd mdi-edit
sudo usermod -a -G mdi-edit ubuntu

#---------------------------------------------------------------
# continue as user ubuntu (i.e., not sudo) to install the MDI
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
echo
go version
singularity --version
echo
echo ~/mdi
ls -l ~/mdi
echo
