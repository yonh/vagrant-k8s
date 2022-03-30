#!/bin/bash
set -e

OS=$(echo `uname`|tr '[:upper:]' '[:lower:]')
sed_args=""


if [ "$OS" == "linux" ] ; then
  sed_args="-i"
elif [ "$OS" == "darwin" ] ; then
  sed_args="-i ''"
else
    exit "not support OS"
fi



### 初始化修改这里的变量为需要的值
# k8s版本
K8S_VERSION="v1.23.5"
# k8s镜像仓库
K8S_IMAGE_REPOSITORY="ghcr.io/yonh" # 可选: docker.io/yonh , registry.cn-hangzhou.aliyuncs.com/google_containers
# master 节点
MASTER_IP="192.168.56.1"
# node 1 节点
NODE1_IP="192.168.56.2"
# node 2 节点
NODE2_IP="192.168.56.3"
# DNS
DNS="114.114.114.114"

VARS=(  "K8S_VERSION: ${K8S_VERSION}"
        "K8S_IMAGE_REPOSITORY: ${K8S_IMAGE_REPOSITORY}"
        "MASTER_IP: ${MASTER_IP}"
        "NODE1_IP: ${NODE1_IP}"
        "NODE2_IP: ${NODE2_IP}"
        "DNS: ${DNS}"
)

FILES=( "./scripts/bootstrap-master.sh"
        "./scripts/bootstrap-node.sh"
        "./Vagrantfile" )


for file in "${FILES[@]}" ; do
    for animal in "${VARS[@]}" ; do
        KEY="${animal%%:*}"
        VALUE="${animal#*: }"
    
        eval "sed $sed_args 's|{{${KEY}}}|${VALUE}|g' $file"
        # rollback config
        #eval "sed $sed_args 's|${VALUE}|{{$KEY}}|g' $file"
    done
done

# for var in ${vars[@]}; do
#     sed $sed_args "s/{{K8S_VERSION}}/${K8S_VERSION}/g" ./scripts/bootstrap-node.sh
# done

