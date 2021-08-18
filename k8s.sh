cat /etc/redhat-release
timedatectl set-timezone Asia/Shanghai

#升级系统
yum install -y epel-release
yum -y update

#删除已有版本docker
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

#同步时间
yum install ntpdate -y
ntpdate time.windows.com


#关闭防火墙

systemctl stop firewalld
systemctl status firewalld
systemctl disable firewalld

#关闭swap

swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab
echo 'vm.swappiness = 0' >> /etc/sysctl.conf
sysctl -p

#关闭selinux

setenforce 0 
sed -i 's/enforcing/disabled/' /etc/selinux/config  

#设置网桥参数

cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF
sysctl --system 


#安装docker

yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

yum install -y docker-ce
systemctl start docker
systemctl enable docker

sudo systemctl daemon-reload
sudo systemctl restart docker
sudo docker run hello-world


#安装k8s源
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

sed -ri 's/kubelet\.conf"/kubelet\.conf --cgroup-driver=cgroupfs"/' /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf

yum list installed | grep kubelet
yum list installed | grep kubeadm
yum list installed | grep kubectl

kubelet --version

kubeadm config images pull
