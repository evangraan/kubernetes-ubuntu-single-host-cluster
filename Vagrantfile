BOX_IMAGE = "ubuntu/focal64"

Vagrant.configure(2) do |config|

  config.vm.define "k8s-control01" do |subconfig|
    subconfig.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.name = "k8s-control01"
        vb.memory = "4096"
        vb.cpus = "2"
      end
    subconfig.vm.hostname = "k8s-control01"
    subconfig.vm.box = BOX_IMAGE
    subconfig.vm.network :public_network, ip: "192.168.1.10", nic_type: "virtio", bridge: "en1: Wi-Fi (AirPort)"
  end

  config.vm.define "k8s-worker01" do |subconfig|
    subconfig.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.name = "k8s-worker01"
        vb.memory = "4096"
        vb.cpus = "2"
      end
    subconfig.vm.hostname = "k8s-worker01"
    subconfig.vm.box = BOX_IMAGE
    subconfig.vm.network :public_network, ip: "192.168.1.11", nic_type: "virtio", bridge: "en1: Wi-Fi (AirPort)"
  end

  config.vm.provision "shell", inline: <<-SHELL
    echo "192.168.1.10 k8s-cluster" >> /etc/hosts
    echo "192.168.1.10 k8s-cluster01" >> /etc/hosts
    echo "192.168.1.11 k8s-worker01" >> /etc/hosts
    echo "192.168.1.12 k8s-worker02" >> /etc/hosts
    git clone https://github.com/evangraan/kubernetes-ubuntu-single-host-cluster
    HOSTNAME=$(hostname)
    if [[ "$HOSTNAME" =~ ^k8s-control ]]; then
      cp kubernetes-ubuntu-single-host-cluster/scripts/control/* .
    fi
    if [[ "$HOSTNAME" =~ ^k8s-worker ]]; then
      cp kubernetes-ubuntu-single-host-cluster/scripts/worker/* .
    fi
    rm -rf kubernetes-ubuntu-single-host-cluster
    chmod +x *.sh
    chmod +x ops*

    mkdir .ssh
    chmod go-rwx .ssh
    cp kubernetes-ubuntu-single-host-cluster/test-keys/* .ssh/
    chmod 0600 .ssh/id_rsa
    chmod 0600 .ssh/authorized_keys
    mkdir .kube
    scp -o "StrictHostKeyChecking no" vagrant@k8s-control01:.kube/config .kube/config
    chown $(id -u):$(id -g) .kube/config

    if [ -e install_control.sh ]; then ./install_control.sh; fi
    if [ -e ops_start_cluster ]; then ./ops_start_cluster 192.168.2.0/24; fi
    if [ -e install_worker.sh ]; then ./install_worker.sh; fi
    if [ -e install_calico_cni.sh ]; then ./install_calico_cni.sh ; fi
    if [ -e install_kube_config.sh ]; then ./install_kube_config.sh; fi
    if [ -e ops_get_nodes ]; then ./ops_get_nodes; fi
  SHELL

end
