# vagrant-k8s
使用Vagrant + Kubeadm 一键初始化一个双节点的K8s集群

解说视频以及相关文章可以来这里看 <https://iyonh.com/k8s/kubeadm-init-cn/>

```Bash

git clone https://github.com/yonh/vagrant-k8s.git
cd vagrant-k8s

# 初始化配置参数，修改init.sh脚本变量 VARS 的值并执行命令
./init.sh

# 等待安装完成,整个过程几分钟到十几分钟不等，如果出错了，请排查具体原因
vagrant up
```
# 安装完成保存快照
vagrant snapshot save init
