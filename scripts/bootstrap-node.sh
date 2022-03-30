#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

# 修改Root用户密码
echo "root:root" | chpasswd

cp /etc/resolv.conf /etc/resolv.conf.bak
echo "nameserver {{DNS}}" > /etc/resolv.conf

# 使用国内源
cp /etc/apt/sources.list /etc/apt/sources.list.bak

#cat <<EOF > /etc/apt/sources.list
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
#deb https://mirrors.aliyun.com/ubuntu/ bionic main
#deb https://mirrors.aliyun.com/ubuntu/ bionic-updates main
#deb https://mirrors.aliyun.com/ubuntu/ bionic universe
#deb https://mirrors.aliyun.com/ubuntu/ bionic-updates universe
#deb https://mirrors.aliyun.com/ubuntu/ bionic-security main
#deb https://mirrors.aliyun.com/ubuntu/ bionic-security universe
#EOF

sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list


# 关闭swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab


cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system


# 添加 kubernetes key
curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg |apt-key add -

# 添加 kubernetes 源
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
#deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
deb https://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-xenial main
EOF

# 安装docker
#curl -skSL https://mirror.azure.cn/repo/install-docker-ce.sh | sh -s -- --mirror AzureChinaCloud

apt-get update && apt-get install -y --no-install-recommends kubeadm kubelet docker.io ntp

# 配置时区
timedatectl set-timezone Asia/Shanghai

cat <<EOF | tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

systemctl enable docker.service
systemctl restart docker.service

hash=`cat /vagrant/scripts/ca-cert-hash`
# join
kubeadm join {{MASTER_IP}}:6443 \
	--token pv5x90.21dmj3k5hq2lveaw \
	--discovery-token-ca-cert-hash sha256:$hash
	#--discovery-token-unsafe-skip-ca-verification
	#--discovery-token-ca-cert-hash sha256:d741c984d357e1e69e8d68fe6d06d8bdb8d056e39d09f6d2e9192466017d44dc
	#--discovery-token-unsafe-skip-ca-verification

