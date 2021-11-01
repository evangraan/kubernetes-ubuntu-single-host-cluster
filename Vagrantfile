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
    echo "192.168.1.10 k8s-control01" >> /etc/hosts
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
    chmod +x *.sh
    chmod +x ops*
    mkdir /home/vagrant/test-keys
    cp -f kubernetes-ubuntu-single-host-cluster/test-keys/* /home/vagrant/.ssh/
    chmod 0600 /home/vagrant/.ssh/test-id_rsa
    cat .ssh/test-id_rsa.pub >> .ssh/authorized_keys
    chown vagrant:vagrant ~/.ssh/*
    rm -rf kubernetes-ubuntu-single-host-cluster
    rm -rf test-keys

    if [ -e install_control.sh ]; then ./install_control.sh; fi
    if [ -e install_worker.sh ]; then ./install_worker.sh; fi
    if [ -e ops_start_cluster ]; then ./ops_start_cluster 192.168.2.0/24; fi

    mkdir -p /home/vagrant/.kube
    if [ -e /home/vagrant/.kube/config ]; then
      ./install_kube_config.sh
    else
      scp -i /home/vagrant/.ssh/test-id_rsa -o "StrictHostKeyChecking no" vagrant@k8s-control01:.kube/config /home/vagrant/.kube/config
    fi
    chown -R $(id -u):$(id -g) /home/vagrant/.kube

    if [ -e install_calico_cni.sh ]; then ./install_calico_cni.sh ; fi
    if [[ "$HOSTNAME" =~ ^k8s-worker ]]; then
      if [ -e install_kube_config.sh ]; then ./install_kube_config.sh; fi
    fi
  SHELL

end
