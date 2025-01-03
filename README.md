### Prerequisite
- Azure CLI
- Terraform
- curl
- jq

### Authentication
Use `az login` to [authenticate](https://learn.microsoft.com/en-us/azure/developer/terraform/get-started-windows-bash?tabs=bash#5-authenticate-terraform-to-azure) deployment to Azure.

### Apply Terraform
User `./terraform-apply.sh` to deploy.

### Update whitelisted IP
User `./update-nsg-ip.sh` to update whilelisted IP to current IP.\
Use `./update-nsg-ip.sh 1.2.3.4` to update whitlelisted IP to certain IP(ex: 1.2.3.4).

### Web Portal
http://{lb-public-ip}\
default password: pwd

### SSH
ssh -v azureuser@{lb-public-ip} -p 22\
with your own pihole.pem paired with public_key in variables.tf

### Init log
tail -f /var/log/cloud-init-output.log
