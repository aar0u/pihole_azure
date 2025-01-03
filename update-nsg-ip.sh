rg=$(terraform output -raw rg_shared | jq -r ".group_name")

if [ -z "$1" ]; then
    ip=$(curl -s https://ipinfo.io | jq -r ".ip")
else
    ip=$1
fi

echo Update source to $ip...

az group list --query "[].name"
nsg=$(az network nsg list --resource-group $rg --query "[].{Name: name}[0].Name" --output tsv)

echo Before:
az network nsg rule list --resource-group $rg --nsg-name $nsg --include-default --query "[].{Name:name, Direction:direction, Source:sourceAddressPrefix, Priority:priority}" --output table

az network nsg rule update --resource-group $rg --nsg-name $nsg --name lb-pool-pihole-ssh --source-address-prefixes $ip | jq '.sourceAddressPrefix + "@" + .destinationPortRange + ": " + .provisioningState'
az network nsg rule update --resource-group $rg --nsg-name $nsg --name lb-pool-pihole-dns --source-address-prefixes $ip | jq '.sourceAddressPrefix + "@" + .destinationPortRange + ": " + .provisioningState'
az network nsg rule update --resource-group $rg --nsg-name $nsg --name lb-pool-pihole-web --source-address-prefixes $ip | jq '.sourceAddressPrefix + "@" + .destinationPortRange + ": " + .provisioningState'

echo After:
az network nsg rule list --resource-group $rg --nsg-name $nsg --include-default --query "[].{Name:name, Direction:direction, Source:sourceAddressPrefix, Priority:priority}" --output table
