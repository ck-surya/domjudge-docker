
# Setup Guide for Secure Server, Docker, Domjudge, and Related Tools

This guide walks you through the process of setting up a secure server with Docker, Domjudge, Traefik, Portainer, and related tools, following best practices for security and configuration.

---

### 1. **Set Timezone and Basic System Setup**

```bash
timedatectl set-timezone 'Asia/Kolkata'  # Set timezone
```

- **Remove Unattended Upgrades**: Disable automatic upgrades for more control.
  
```bash
apt --assume-yes remove unattended-upgrades
```

- **Update and Upgrade Packages**:

```bash
apt --assume-yes update
apt --assume-yes upgrade
```

- **Install Common Utilities**:

```bash
apt install nano htop fail2ban ufw plocate
```

- **Set Default Firewall Rules**:

```bash
ufw default deny incoming
ufw default allow outgoing
ufw app list
ufw allow OpenSSH
ufw show added
ufw status numbered
ufw enable
ufw status numbered
```

---

### 2. **Modify GRUB Configuration for Cgroup Support**

1. **Edit GRUB Configuration**:
   
   Open the GRUB configuration file to add required settings for memory and swap accounting.

```bash
vim /etc/default/grub
```

   Add the following to `GRUB_CMDLINE_LINUX_DEFAULT`:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="cgroup_enable=memory swapaccount=1 systemd.unified_cgroup_hierarchy=0"
```

2. **Update GRUB and Reboot**:

```bash
update-grub
reboot
```

---

### 3. **Create a Non-root User for SSH and Sudo**

1. **Create and Configure the Non-root User**:

```bash
mkdir nonroot
vim nonroot/cloud-config.sh
```

   Add the following script to configure a new non-root user with SSH access and sudo privileges:

```bash
#!/bin/bash
set -euo pipefail

USERNAME=ubuntu # TODO: Customize the sudo non-root username here

# Create user and immediately expire password to force a change on login
useradd --create-home --shell "/bin/bash" --groups sudo "${USERNAME}"
passwd --delete "${USERNAME}"
chage --lastday 0 "${USERNAME}"

# Create SSH directory for sudo user and move keys over
home_directory="$(eval echo ~${USERNAME})"
mkdir --parents "${home_directory}/.ssh"
cp /root/.ssh/authorized_keys "${home_directory}/.ssh"
chmod 0700 "${home_directory}/.ssh"
chmod 0600 "${home_directory}/.ssh/authorized_keys"
chown --recursive "${USERNAME}":"${USERNAME}" "${home_directory}/.ssh"

# Disable root SSH login with password
sed --in-place 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
systemctl restart ssh
```

2. **Execute the Script**:

```bash
cd nonroot
chmod 775 cloud-config.sh
./cloud-config.sh
```

---

### 4. **Configure SSH for Security**

1. **Update `/etc/ssh/sshd_config`**:

   - Disable root login and password authentication for security:

```bash
vim /etc/ssh/sshd_config
```

   - Update the following settings:

```bash
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
```

2. **Update SSH Config in `sshd_config.d`**:

```bash
cd /etc/ssh/sshd_config.d
sudo nano 50-cloud-init.conf
```

   - Set `PasswordAuthentication` to `no`.

```bash
PasswordAuthentication no
```

3. **Restart SSH**:

```bash
sudo systemctl restart ssh
```

---

### 5. **Install Docker and Configure User**

1. **Install Docker**:

```bash
sudo curl -fsSL https://get.docker.com | bash
```

2. **Add the User to the Docker Group**:

```bash
sudo usermod -aG docker ubuntu
su - ubuntu  # or log out and back in to use the docker group
```

---

### 6. **Clone and Set Up Domjudge Docker**

1. **Clone the Domjudge Docker Repository**:

```bash
git clone https://github.com/ICPC-India/domjudge-docker.git
cd domjudge-docker
```

2. **Set Environment Variables**:

```bash
export EMAIL=anup.kalbalia@gmail.com
export TRAEFIK_DOMAIN=traefik.test1.indiaicpc.in  # Replace with your domain
export HASHED_PASSWORD=$(openssl passwd -apr1)  # Generate hashed password for Traefik
echo $HASHED_PASSWORD > traefik_pass.txt
```

3. **Set Up Traefik**:

```bash
docker compose -f traefik.yml up -d
```

4. **Set Up Portainer**:

```bash
export PORTAINER_DOMAIN=portainer.test1.indiaicpc.in  # Replace with your domain
docker compose -f portainer.yml up -d
```

5. **Set Up MariaDB**:

```bash
export DJ_DB=domjudge
export DJ_DB_USER=domjudge
export DJ_DB_PASSWORD=djpw
export DB_ROOT_PASSWORD=rootpw
docker compose -f mariadb.yml up -d
```

6. **Set Up DOMjudge Server**:

```bash
docker compose -f domserver.yml up -d
```

7. **Check Logs and Get Admin/Host Passwords**:

   After setting up, check the logs of the DOMjudge container:

```bash
docker logs <domjudge_container_id>
```

   - Copy the admin and judgehost passwords from the log output.
   - Set the `JUDGEHOST_PASSWORD` environment variable.

```bash
export JUDGEHOST_PASSWORD=SOMEPASSWORD
```

8. **Generate Judgehosts**:

```bash
./generate-judgehosts-compose.sh
```

---

### 7. **Verify Everything Is Running**

- **Check Docker Containers**:

```bash
docker ps
```

- **Verify Firewall**:

```bash
ufw status numbered
```

- **Access Web Interfaces**:
   - Traefik: `http://<TRAEFIK_DOMAIN>`
   - Portainer: `http://<PORTAINER_DOMAIN>`

---

### Notes:

- Ensure that the `JUDGEHOST_PASSWORD` and `ADMIN_PASSWORD` are set correctly in the environment or `initial_admin_password.secret` file.
- Replace all placeholder domain names and passwords with your actual values.
- You may need to adjust firewall and security rules depending on your network environment.

--- 
