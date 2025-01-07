#! /bin/bash
sudo apt-get update
sudo apt-get install -y sqlite3
# sudo apt-get install -y apache2
# sudo systemctl start apache2
# sudo systemctl enable apache2
# echo "<h1>Azure Linux VM with Web Server</h1>" | sudo tee /var/www/html/index.html

echo WEBPASSWORD: pwd

sudo cat << EOF >> /etc/hosts
${public_ip} pi.home
192.168.31.171 mb.home
192.168.31.172 tv.home
192.168.31.173 print.home
EOF

sudo mkdir -p /etc/pihole

sudo tee /etc/pihole/setupVars.conf > /dev/null << EOF
PIHOLE_INTERFACE=eth0
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
CACHE_SIZE=10000
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSMASQ_LISTENING=all
WEBPASSWORD=5741419e48642ffe1ce6f186c120765cf4a91c6e9bd69ff37858e6cc0f237e94
BLOCKING_ENABLED=true
PIHOLE_DNS_1=8.8.8.8
PIHOLE_DNS_2=8.8.4.4
DNSSEC=false
REV_SERVER=false
EOF

curl -sSL https://install.pi-hole.net | sudo bash /dev/stdin --unattended

sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/master/anti-ad-domains.txt', 1, 'anti-AD');"

# Update the list of ad-serving domains
pihole -g

sudo apt-get install -y python3-pip
# Install Flask and Azure SDK dependencies
sudo pip3 install flask azure-identity azure-mgmt-network

# Create script directory
mkdir -p /home/${username}/scripts
chown -R ${username}:${username} /home/${username}/scripts

# Copy the NSG update script
cat << EOF > /home/${username}/scripts/service_nsg.py
${file("${module_path}/scripts/service_nsg.py")}
EOF

# Create environment file with Azure environment variables
cat << EOF > /home/${username}/scripts/.env
AZURE_SUBSCRIPTION_ID=${subscription_id}
AZURE_RESOURCE_GROUP=${resource_group_name}
AZURE_NSG_NAME=${nsg_name}
EOF

# Set up Azure environment variables with actual values from Terraform
cat << EOF >> /home/${username}/.bashrc

$(sed 's/^/export /' "/home/${username}/scripts/.env")
EOF

# Ensure environment variables are loaded immediately
source /home/${username}/.bashrc

# Add a systemd service to run the Flask app
cat << EOF | sudo tee /etc/systemd/system/service_nsg.service
[Unit]
Description=Update NSG IP Service
After=network.target

[Service]
User=${username}
WorkingDirectory=/home/${username}/scripts
ExecStart=/usr/bin/python3 /home/${username}/scripts/service_nsg.py
Restart=always
EnvironmentFile=/home/${username}/scripts/.env

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl enable service_nsg.service
sudo systemctl start service_nsg.service
systemctl status service_nsg
