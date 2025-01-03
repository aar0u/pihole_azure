ip=$(curl -s https://ipinfo.io | jq -r ".ip")
terraform apply -var="username=azureuser" -var="source_ip=$ip"
