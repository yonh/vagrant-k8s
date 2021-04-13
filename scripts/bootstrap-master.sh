#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

# 修改Root用户密码
echo "root:root" | chpasswd

cp /etc/resolv.conf /etc/resolv.conf.bak
echo "nameserver 114.114.114.114" > /etc/resolv.conf


# 使用国内源
cp /etc/apt/sources.list /etc/apt/sources.list.bak

cat <<EOF > /etc/apt/sources.list
# azure
#deb http://azure.archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse
#deb http://azure.archive.ubuntu.com/ubuntu/ bionic-security main restricted universe multiverse
#deb http://azure.archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse
#deb http://azure.archive.ubuntu.com/ubuntu/ bionic-proposed main restricted universe multiverse
#deb http://azure.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse
# 163
#deb http://mirrors.163.com/ubuntu/ bionic main restricted universe multiverse
#deb http://mirrors.163.com/ubuntu/ bionic-security main restricted universe multiverse
#deb http://mirrors.163.com/ubuntu/ bionic-updates main restricted universe multiverse
#deb http://mirrors.163.com/ubuntu/ bionic-proposed main restricted universe multiverse
#deb http://mirrors.163.com/ubuntu/ bionic-backports main restricted universe multiverse
# aliyun
deb https://mirrors.aliyun.com/ubuntu/ bionic main
deb https://mirrors.aliyun.com/ubuntu/ bionic-updates main
deb https://mirrors.aliyun.com/ubuntu/ bionic universe
deb https://mirrors.aliyun.com/ubuntu/ bionic-updates universe
deb https://mirrors.aliyun.com/ubuntu/ bionic-security main
deb https://mirrors.aliyun.com/ubuntu/ bionic-security universe
EOF

#echo "cat /etc/apt/sources.list..."
#cat /etc/apt/sources.list



# 关闭swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab


# 添加 kubernetes key
curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg |apt-key add -

# 添加 kubernetes 源
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
#deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
deb https://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-xenial main
EOF

# 安装docker
#curl -skSL https://mirror.azure.cn/repo/install-docker-ce.sh | sh -s -- --mirror AzureChinaCloud

apt-get update && apt-get install -y --no-install-recommends kubelet kubeadm kubectl docker.io
systemctl enable docker.service

k8s_version="v1.21.0"
k8s_image_repository="docker.io/yonh"

# 由于coredns镜像命名为 k8s.gcr.io/coredns/coredns:v1.21.0, coredns存在于另一个项目中，无法实现在 docker hub中，所以这里手动替换名称
coredns_image=`kubeadm config images list --kubernetes-version=${k8s_version} --image-repository=${k8s_image_repository} |grep coredns/coredns`
replace_image=${coredns_image/coredns\/coredns/coredns}
docker pull $replace_image
docker tag $replace_image $coredns_image
docker rmi $replace_image


kubeadm init \
	--token=pv5x90.21dmj3k5hq2lveaw \
	--apiserver-advertise-address=192.168.100.10 \
	--image-repository=${k8s_image_repository} \
	--pod-network-cidr=10.244.0.0/16 \
	--ignore-preflight-errors=NumCPU \
	--ignore-preflight-errors=Mem \
	--kubernetes-version=v1.21.0
	# --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers \

sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#CURR_DIR="$( cd "$( dirname "$0" )" && pwd )"
kubectl apply -f /vagrant/scripts/kube-flannel.yml


# 生成 kubeadm join 命令需要的 discovery-token-ca-cert-hash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //' > /vagrant/scripts/ca-cert-hash
# 也可以使用创建token命令或忽略hash校验解决
# kubeadm token create --print-join-command

# join
#kubeadm join 192.168.100.10:6443 \
#	--token pv5x90.21dmj3k5hq2lveaw \
#	--discovery-token-ca-cert-hash sha256:d741c984d357e1e69e8d68fe6d06d8bdb8d056e39d09f6d2e9192466017d44dc

