#!/bin/bash
# This is a server setup script for ${amazon_server} on the Amazon CentOS 6.3 minimal r2 image
set -x

DEBUG=true
amazon_server=ec2-54-224-12-98.compute-1.amazonaws.com
git_version=1.8.2
node_version=v0.10.3
arch=x86_64
git_dir=/data/git
blog_dir=${git_dir}/drewsblog.git


function die() {
  echo "Error: ${1}";
  exit 1;
}

function install_admin_pkgs() {
  sudo yum install -y htop.${arch} monit.${arch} lynx.${arch} telnet.${arch}
  sudo yum install -y mlocate.${arch} && sudo updatedb &
  sudo echo 'PATH=$PATH:/usr/local/bin:/usr/bin:/usr/sbin:/usr/local/sbin' >> /root/.bashrc
  sudo echo 'export PATH' >> /root/.bashrc
  echo 'PATH=$PATH:/usr/local/bin:/usr/bin:/usr/sbin:/usr/local/sbin' >> ~/.bashrc
  echo 'export PATH' >> ~/.bashrc
}

function install_devel_pkgs() {
  sudo yum install -y curl-devel.${arch} expat-devel.${arch} gettext-devel.${arch} openssl-devel.${arch} zlib-devel.${arch} gcc.${arch} mak
e.${arch} glibc.${arch} perl-ExtUtils-MakeMaker.${arch} gcc-c++.${arch} compat-gcc-32.${arch} compat-gcc-32-c++.${arch}
}

function install_git() {
  cd /usr/local/src
  sudo wget http://git-core.googlecode.com/files/git-${git_version}.tar.gz || die "No git version ${git_version} found. Aborting."
  sudo tar -xvzf git-${git_version}.tar.gz
  pushd git-${git_version}
  sudo ./configure
  sudo make
  sudo make install
  popd
  sudo rm git-${git_version}*.tar.gz*
}

function start_git() {
    sudo cat > /etc/xinet.d/git <<EOF
  service git
  {
        disable = no
        type            = UNLISTED
        port            = 9418
        socket_type     = stream
        wait            = no
        user            = ec2-user
        server          = /usr/local/bin/git
        server_args     = daemon --inetd --export-all --base-path=/data/git
        log_on_failure  += USERID
  }
EOF
  sudo chkconfig xinetd on && sudo service xinetd restart
}

# Install Node and npm
function install_node() {
  sudo /usr/local/bin/git clone https://github.com/joyent/node.git /usr/local/src/node.js
  pushd /usr/local/src/node.js
  sudo /usr/local/bin/git checkout ${node_version}
  sudo ./configure
  sudo make
  sudo make install
}

# Install Wheat
function install_node_pkgs() {
  sudo /usr/local/bin/npm install -g wheat proto git-fs step haml datetime simple-mime stack creationix
}

# Setup blog git repo
function setup_blog() {
  sudo mkdir -p ${blog_dir} && chown -R ec2-user:ec2-user ${git_dir}
  sudo /usr/local/bin/git clone https://github.com/joyent/node.git /usr/local/src/node.js
  pushd /usr/local/src/node.js
  sudo /usr/local/bin/git checkout ${node_version}
  sudo ./configure
  sudo make
  sudo make install
}

# Install Wheat
function install_node_pkgs() {
  sudo /usr/local/bin/npm install -g wheat proto git-fs step haml datetime simple-mime stack creationix
}

# Setup blog git repo
function setup_blog() {
  sudo mkdir -p ${blog_dir} && chown -R ec2-user:ec2-user ${git_dir}
  mkdir ${blog_dir}/authors ${blog_dir}/articles ${blog_dir}/server ${blog_dir}/skin
  cd $(dir $0) && cp -R authors/ ${blog_dir}/authors && cp -R articles/ ${blog_dir}/articles && cp -R skin/ ${blog_dir}/skin
  cp server.js ~/blog.js
  /usr/local/bin/git init --bare ${blog_dir}
}

function start_node() {
  node ~/blog.js &
}


# ===== MAIN =====
sudo service iptables stop
#if [ "$DEBUG" == "false" ]; then
install_admin_pkgs
install_devel_pkgs
install_git
install_node
install_node_pkgs
#fi
setup_blog
start_git
start_node
