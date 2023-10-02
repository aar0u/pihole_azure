#! /bin/bash
sudo apt-get update
sudo apt-get install -y sqlite3
# sudo apt-get install -y apache2
# sudo systemctl start apache2
# sudo systemctl enable apache2
# echo "<h1>Azure Linux VM with Web Server</h1>" | sudo tee /var/www/html/index.html

echo WEBPASSWORD: pwd
echo ${public_ip} pi.home | sudo tee -a /etc/hosts

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

pihole -g
