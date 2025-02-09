set -exu

apt-get -y install wget

pushd ./src

bash base.sh

popd
