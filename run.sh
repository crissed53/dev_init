set -exu

# Check if user has sudo privileges
if ! sudo -n true 2>/dev/null; then
    echo "This script requires sudo privileges. Please run with a user that has sudo access."
    exit 1
fi

DEBIAN_FRONTEND=noninteractive sudo apt install -y \
    curl wget unzip zip bzip2 gzip tar git vim less openssh-client \
    openssh-server screen htop iotop nmap net-tools iputils-ping \
    build-essential python3-venv

pushd ./scripts

bash base.sh

popd
