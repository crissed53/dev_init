set -exu

DEBIAN_FRONTEND=noninteractive apt install -y \
    curl wget unzip zip bzip2 gzip tar git vim less openssh-client \
    openssh-server screen htop iotop nmap net-tools iputils-ping \
    build-essential python3-venv

pushd ./src

bash base.sh

popd
