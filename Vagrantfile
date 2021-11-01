BOX_IMAGE = "ubuntu/focal64"
HOME = "/home/vagrant"
OWNERSHIP = "vagrant:vagrant"
REPO = "kubernetes-ubuntu-single-host-cluster"
USER = "vagrant"

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
    git clone https://github.com/evangraan/REPO
    HOSTNAME=$(hostname)
    if [[ "$HOSTNAME" =~ ^k8s-control ]]; then
      cp REPO/scripts/control/* .
    fi
    if [[ "$HOSTNAME" =~ ^k8s-worker ]]; then
      cp REPO/scripts/worker/* .
    fi
    chmod +x *.sh
    chmod +x ops*
    chown OWNERSHIP *
    cp -f REPO/test-keys/* HOME/.ssh/
    chmod 0600 HOME/.ssh/test-id_rsa
    cat .ssh/test-id_rsa.pub >> .ssh/authorized_keys
    chown -R OWNERSHIP HOME/.ssh
    rm -rf REPO
    rm -rf test-keys

    if [ -e install_control.sh ]; then ./install_control.sh; fi
    if [ -e install_worker.sh ]; then ./install_worker.sh; fi
    if [ -e ops_start_cluster ]; then sudo -H -u USER bash -c "cd HOME && ./ops_start_cluster 192.168.2.0/24"; fi

    mkdir -p HOME/.kube
    if [ -e install_kube_config.sh ]; then
      sudo -H -u USER bash -c "cd HOME && ./install_kube_config.sh"
    else
      scp -i HOME/.ssh/test-id_rsa -o "StrictHostKeyChecking no" USER@k8s-control01:.kube/config HOME/.kube/config
    fi
    chown -R OWNERSHIP HOME/.kube

    if [ -e install_calico_cni.sh ]; then sudo -H -u USER bash -c "cd HOME && ./install_calico_cni.sh" ; fi

    if [[ "$HOSTNAME" =~ ^k8s-control ]]; then
      sudo -H -u USER bash -c "./ops_generate_join_tokens"
    fi
    if [[ "$HOSTNAME" =~ ^k8s-worker ]]; then
      scp -i HOME/.ssh/test-id_rsa -o "StrictHostKeyChecking no" USER@k8s-control01:join-token HOME/
      chown -R OWNERSHIP HOME/join-token
      scp -i HOME/.ssh/test-id_rsa -o "StrictHostKeyChecking no" USER@k8s-control01:join-hash HOME/
      chown -R OWNERSHIP HOME/join-hash
      TOKEN=$(cat HOME/join-token | sed 's/\n//g')
      HASH=$(cat HOME/join-jash | sed 's/\n//g')
      sudo -H -u USER bash -c "./ops_join_cluster $TOKEN $HASH --no-wait"
    fi
  SHELL
end
