set -exu

apt install -y \
    curl wget unzip zip bzip2 gzip tar git vim less openssh-client \
    openssh-server screen htop iotop nmap net-tools iputils-ping \
    build-essential

pushd ./src

bash base.sh

popd
