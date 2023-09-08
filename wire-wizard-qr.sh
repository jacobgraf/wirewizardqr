#!/bin/bash

#######################################
#####   User-Editable Variables   #####
#######################################

# Default WireGuard Port
defaultPort=51820

# Default Device Name
# This is used as a prefix for the default generated device name.
# e.g. My Device XXXXX (where XXXXX is a random 5 character string)
defaultDevicePrefix="My Device"

# Default Allowed IPs
defaultAllowedIPs="0.0.0.0/0"

# Default Interface Address
defaultInterfaceAddress="10.10.10.2/32"

# Default DNS Server
defaultDNSServer="192.168.1.1"

# Predefined Public Key Server Names & Associated Keys
publicKeyNames=("Server 1" "Server 2" "Server 3")
publicKeys=("public-key-1" "public-key-2" "public-key-3")

# Prefefined WireGuard Endpoints
endpoints=("11.11.11.11" "22.22.22.22" "33.33.33.33")

#################################
#####   DO NOT EDIT BELOW   #####
#################################

# Generate Default Device Name with Random 5 Character String
RAND=$(LC_ALL=C LANG=C tr -dc 'A-Z0-9' </dev/urandom | head -c 5)
defaultDeviceName="$defaultDevicePrefix $RAND"

# Select Device Name
echo
read -p "Enter Device Name [$defaultDeviceName]: " deviceName
[[ -z "$deviceName" ]] && deviceName="$defaultDeviceName"

# Validate Device Name
if [[ ! "$deviceName" =~ ^[A-Za-z0-9_-][A-Za-z0-9\ _-]*$ ]]; then
  echo "Invalid Device Name"
  exit 1
fi

# Convert deviceName to kebab-case
kebabCaseDeviceName=$(echo "$deviceName" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# Set/Create Output Directory Based on Device Name
outputDir="WireGuard - $deviceName"
mkdir -p "$outputDir"

# Select Public Key
echo
echo "Select Public Key:"
echo
for i in "${!publicKeyNames[@]}"; do
  echo "$((i + 1)). ${publicKeyNames[i]}"
done
echo "$((${#publicKeyNames[@]} + 1)). Other"
echo
read -p "Choice [${publicKeyNames[0]}]: " choice
if [[ -z "$choice" ]]; then
  name="${publicKeyNames[0]}"
  publicKey="${publicKeys[0]}"
else
  if [[ "$choice" -eq "$((${#publicKeyNames[@]} + 1))" ]]; then
    echo
    read -p "Enter Public Key: " publicKey
  else
    name="${publicKeyNames[$((choice - 1))]}"
    publicKey="${publicKeys[$((choice - 1))]}"
  fi
fi

# Select Interface Address
echo
read -p "Enter Interface Address [${defaultInterfaceAddress}]: " interfaceAddress

# Select DNS Server
echo
read -p "Enter DNS Server [${defaultDNSServer}]: " dnsServer

# Select Allowed IPs
echo
read -p "Enter Allowed IPs [${defaultAllowedIPs}]: " allowedIPs

# Select Endpoint
echo
echo "Select Endpoint: "
echo
for i in "${!endpoints[@]}"; do
  echo "$((i + 1)). ${endpoints[i]}"
done
echo "$((${#endpoints[@]} + 1)). Other"
echo
read -p "Choice [${endpoints[0]}]: " choice
if [[ -z "$choice" ]]; then
  endpoint="${endpoints[0]}"
else
  if [[ "$choice" -eq "$((${#endpoints[@]} + 1))" ]]; then
    echo
    read -p "Enter Endpoint: " endpoint
  else
    endpoint="${endpoints[$((choice - 1))]}"
  fi
fi

# Select Port
echo
read -p "Enter port [$defaultPort]: " port

# Validate Port
echo
echo "Generating keys..."
wg genkey | tee "$outputDir/key-private-$kebabCaseDeviceName.key" | wg pubkey >"$outputDir/key-public-$kebabCaseDeviceName.key"

privateKey=$(cat "$outputDir/key-private-$kebabCaseDeviceName.key")
publicKey=$(cat "$outputDir/key-public-$kebabCaseDeviceName.key")

echo
echo "Creating WireGuard config..."
configFile="$outputDir/$deviceName.conf"
cat >"$configFile" <<EOL
[Interface]
PrivateKey = $privateKey
Address = ${interfaceAddress:-$defaultInterfaceAddress}
DNS = ${dnsServer:-$defaultDNSServer}

[Peer]
PublicKey = $publicKey
AllowedIPs = ${allowedIPs:-$defaultAllowedIPs}
Endpoint = ${endpoint}:${port:-$defaultPort}
EOL

# Generate QR Code
echo
echo "Generating QR Code..."
qrencode -r "$configFile" -o "$outputDir/$deviceName.png"

# Script Complete!
echo
echo "All done! Files are saved in the directory $outputDir."

# Ask to run again
while true; do
  echo
  read -p "Would you like to run the script again? [Y/n]: " yn
  [[ -z "$yn" ]] && yn="Y"
  case $yn in
  [Yy]*) exec "$0" ;;
  [Nn]*) exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done
