apt-get update && apt-get install -y openssh-server
sudo apt-get install -y iptables-persistent netfilter-persistent
sudo iptables -I INPUT -p tcp --dport 8000:33333 -j ACCEPT
sudo netfilter-persistent save # for reboot
sudo sed -i '/^#\?Port /c\Port 33333' /etc/ssh/sshd_config

# Root login only with keys
sudo sed -i '/^#\?PermitRootLogin /c\PermitRootLogin prohibit-password' /etc/ssh/sshd_config

# Disable password login
sudo sed -i '/^#\?PasswordAuthentication /c\PasswordAuthentication no' /etc/ssh/sshd_config

# Enable pubkey auth
sudo sed -i '/^#\?PubkeyAuthentication /c\PubkeyAuthentication yes' /etc/ssh/sshd_config

# Set authorized keys file
sudo sed -i '/^#\?AuthorizedKeysFile /c\AuthorizedKeysFile .ssh/authorized_keys' /etc/ssh/sshd_config


chmod 700 /root
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
chown -R root:root /root/.ssh
# turn off socket activation and start the service
systemctl disable --now ssh.socket
systemctl daemon-reload
systemctl enable --now ssh.service
systemctl status ssh.service
