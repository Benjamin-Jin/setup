#!/bin/bash

### Check OS ####
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi
echo "OS : $OS"
echo "VERSION : $VER"

echo "Installing Basic Packages For Setting For $OS"
### SETTING UP PATHS ###
export TOOLS_ROOT=/sifive/tools
sudo mkdir -p $TOOLS_ROOT
mkdir tools-build
export TOOLS_BUILD_DIR=$PWD/tools-build

### ASK ###

### START ###
cd $TOOLS_BUILD_DIR

if [[ $OS = *"Ubuntu"* ]]; then
	sudo apt-get install openjdk-8-jdk makedev fuse libfuse-dev libsqlite3-dev libgmp-dev libncurses5-dev pkg-config git g++ gcc libre2-dev device-tree-compiler libfdt-dev autoconf automake libtool unzip flex bison libfl-dev gdebi-core build-essential checkinstall libreadline-gplv2-dev libncursesw5-dev libssl-dev libgdbm-dev libc6-dev libbz2-dev zlib1g-dev openssl libffi-dev python3 wget curl cmake

	# node
	echo "######## Installing Node ########"
	curl -sL https://deb.nodesource.com/setup_11.x -o nodesource_setup.sh
	sudo bash nodesource_setup.sh
	sudo apt-get install nodejs

	# prince on ubuntu 16.04
	echo "######## Installing Prince ########"
	if [[ $VER = *"16"* ]]; then
		wget https://www.princexml.com/download/prince_12.4-1_ubuntu16.04_amd64.deb
		gdebi prince_12.4-1_ubuntu16.04_amd64.deb
	elif [[ $VER = *"18"* ]]; then
		# prince on ubuntu 18.04
		wget https://www.princexml.com/download/prince_12.4-1_ubuntu18.04_amd64.deb
		gdebi prince_12.4-1_ubuntu18.04_amd64.deb
	else
		echo "### Version mismatch ###"
		echo "### Exiting with Error! ###"
		exit 1
	fi

	sudo apt-get install environment-modules

elif [[ $OS = *"CentOS"* ]] && [[ $VER = *"7"* ]]; then
	# git 2.x should be used
	echo "### gib 2.x should be used. Installing Required Packages ###"
	sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
	sudo yum -y erase git
	sudo yum -y install epel-release centos-release-scl
	sudo yum -y install git2u fuse fuse-devel sqlite-devel gmp-devel ncurses-devel pkgconfig gcc gcc-c++
	sudo yum -y install re2-devel dash java-1.8.0-openjdk java-1.8.0-openjdk-devel mpfr-devel libmpc-devel libffi-devel dtc libfdt-devel openssl-devel libedit-devel libX11-devel python3

	# Installing Other Packages

	sudo yum -y install wget lbzip2 rsync autoconf flex bison unzip

	# it requires at runtime of ip-onboarding
	sudo yum -y install devtoolset-7-gcc devtoolset-7-gcc-c++

	# environment modules
	sudo yum -y install environment-modules

	# tar (--version >= 1.32)
	wget https://ftp.gnu.org/gnu/tar/tar-1.32.tar.gz
	tar xvf tar-1.32.tar.gz
	cd tar-1.32
	./configure --prefix=/usr
	make -j8
	sudo make install
	cd $TOOLS_BUILD_DIR

	# node
	curl -sL https://rpm.nodesource.com/setup_11.x -o nodesource_setup.sh
	sudo bash nodesource_setup.sh
	sudo yum -y install nodejs

	# prince
	wget https://www.princexml.com/download/prince-12.4-1.centos7.x86_64.rpm
	sudo yum -y localinstall ./prince-12.4-1.centos7.x86_64.rpm
else
	echo "### OS mismatched! ###"
	echo "### Exiting With Error! ###"
	exit 1
fi



cd $TOOLS_BUILD_DIR
wget https://sourceforge.net/projects/tcl/files/Tcl/8.6.5/tcl8.6.5-src.tar.gz
tar xvf tcl8.6.5-src.tar.gz
cd tcl8.6.5
cd unix
./configure --prefix=$TOOLS_ROOT/tcltk/tcl/8.6.5
make -j8
sudo make install
cd $TOOLS_BUILD_DIR

wget https://sourceforge.net/projects/tclx/files/TclX/8.4.1/tclx8.4.1.tar.bz2
tar xvf tclx8.4.1.tar.bz2
cd tclx8.4
./configure
make
sudo make install
sudo cp $TOOLS_ROOT/tcltk/tcl/8.6.5/lib/tclx8.4/libtclx8.4.so $TOOLS_ROOT/tcltk/tcl/8.6.5/lib/libtclx8.4.so
cd $TOOLS_BUILD_DIR

wget https://sourceforge.net/projects/tcl/files/Tcl/8.6.5/tk8.6.5-src.tar.gz
tar xvf tk8.6.5-src.tar.gz
cd tk8.6.5
cd unix
./configure --prefix=$TOOLS_ROOT/tcltk/tk/8.6.5
make -j8
sudo make install
cd $TOOLS_BUILD_DIR

wget https://sourceforge.net/projects/modules/files/Modules/modules-3.2.10/modules-3.2.10.tar.gz
tar xvf modules-3.2.10.tar.gz
cd modules-3.2.10
LDFLAGS="-Wl,-rpath=$TOOLS_ROOT/tcltk/tcl/8.6.5/lib" ./configure --with-tcl=$TOOLS_ROOT/tcltk/tcl/8.6.5/lib --with-tcl-ver=8.6 --with-tclx-lib=$TOOLS_ROOT/tcltk/tcl/8.6.5/lib/tclx8.4 --with-tclx-ver=8.4 --prefix=$TOOLS_ROOT --with-module-path=$TOOLS_ROOT/Modules/3.2.10 --with-version-path=$TOOLS_ROOT/Modules/versions CPPFLAGS="-DUSE_INTERP_ERRORLINE"
make -j8
sudo make install
cd $TOOLS_BUILD_DIR

cd $TOOLS_ROOT/Modules
sudo ln -s 3.2.10 default
echo $TOOLS_ROOT"/Modules/default/sifive" | sudo tee -a default/init/.modulespath > /dev/null
unset MODULEPATH
source $TOOLS_ROOT/Modules/default/init/bash
module avail
cd $TOOLS_BUILD_DIR

echo "##### Installing wit #####"
mkdir wit
cd wit
export WIT_VERSION=0.12.0
git clone https://github.com/sifive/wit.git v"$WIT_VERSION"
cd v"$WIT_VERSION"
git checkout v"$WIT_VERSION"
sudo make install PREFIX=$TOOLS_ROOT/sifive/wit
cd $TOOLS_BUILD_DIR

echo "##### Installing wake #####"
mkdir wake
cd wake
export WAKE_VERSION=0.17.2
git clone https://github.com/sifive/wake.git "v"$WAKE_VERSION
cd "v"$WAKE_VERSION
git checkout "v"$WAKE_VERSION
make -j8
sudo ./bin/wake 'install "'$TOOLS_ROOT'/sifive/wake/'$WAKE_VERSION'"'
cd $TOOLS_BUILD_DIR

echo "##### Installing protobuf #####"
wget https://github.com/protocolbuffers/protobuf/releases/download/v3.5.1/protobuf-all-3.5.1.tar.gz
tar xvf protobuf-all-3.5.1.tar.gz
cd protobuf-3.5.1/
./configure --prefix=$TOOLS_ROOT/google/protobuf/3.5.1
make -j8
sudo make install
cd $TOOLS_BUILD_DIR

echo "##### Installing verilator #####"
export VERILATOR_VERSION=4.008
mkdir verilator
cd verilator
git clone http://git.veripool.org/git/verilator verilator-$VERILATOR_VERSION
cd verilator-$VERILATOR_VERSION/
git checkout v$VERILATOR_VERSION
autoconf
./configure --prefix=$TOOLS_ROOT/verilator/$VERILATOR_VERSION
make -j8
sudo make install
cd $TOOLS_BUILD_DIR

echo "##### Installing perl #####"
wget https://www.cpan.org/src/5.0/perl-5.22.2.tar.gz
tar -xzf perl-5.22.2.tar.gz
cd perl-5.22.2
./Configure -des -Dprefix=$TOOLS_ROOT/perl/perl/5.22.2 -Dusethreads
make -j8
sudo make install
cd $TOOLS_BUILD_DIR

echo "##### Installing python3 #####"
wget https://www.python.org/ftp/python/3.7.1/Python-3.7.1.tar.xz
tar xvf Python-3.7.1.tar.xz
cd Python-3.7.1
./configure --prefix=$TOOLS_ROOT/python/python/3.7.1 --enable-optimizations
make -j8
sudo make install
sudo $TOOLS_ROOT/python/python/3.7.1/bin/python3.7 -m pip install --upgrade pip
cd $TOOLS_BUILD_DIR

echo "##### Installing ruby #####"
wget https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.1.tar.gz
tar xvf ruby-2.5.1.tar.gz
cd ruby-2.5.1/
./configure --prefix=$TOOLS_ROOT/ruby/ruby/2.5.1
make -j8
sudo make install
unset GEM_PATH
unset MY_RUBY_HOME
unset GEM_HOME
sudo $TOOLS_ROOT/ruby/ruby/2.5.1/bin/gem install bundler --version=1.16.2
cd $TOOLS_BUILD_DIR

echo "##### Installing cmake(CentOS only) #####"
if [[ $OS = *"CentOS"* ]]; then
	wget https://cmake.org/files/v3.6/cmake-3.6.2.tar.gz
	tar -zxvf cmake-3.6.2.tar.gz
	cd cmake-3.6.2
	./bootstrap --prefix=$TOOLS_ROOT/cmake/3.6.2
	make -j8
	sudo make install
	export PATH=$TOOLS_ROOT/cmake/3.6.2/bin:$PATH
	cd $TOOLS_BUILD_DIR
fi

echo "##### Installing clang #####"
wget https://github.com/llvm/llvm-project/archive/llvmorg-7.0.0.zip
unzip llvmorg-7.0.0.zip
cd llvm-project-llvmorg-7.0.0
mkdir build
cd build
cmake -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_INSTALL_PREFIX=$TOOLS_ROOT/clang/clang+llvm-7.0.0-x86_64-linux-gnu -DCMAKE_BUILD_TYPE=MinSizeRel -G "Unix Makefiles" ../llvm
make -j8
sudo make install
cd $TOOLS_BUILD_DIR

exit 0
