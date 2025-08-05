# dev_init

## setting up ssh (root)
```bash
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
sed -i 's/^#*Port .*/Port 33333/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
```
