#!/usr/bin/env bash

# Arknights
# Has specific API for getting download links
echo "Updating Arknights..."
PAGE=$(curl -sSL "https://www.arknights.global/api/resource/game-download-link?index=1&size=999")
ARKNIGHTS=$(echo $PAGE | jq -r ".data.rows[0].client")
sed -i "s@http.*Arknights_EN.*exe@$ARKNIGHTS@" ./home/profiles/gaming.nix
echo "Done!"

# Arknights: Endfield
# Dynamic URL used directly; should be no need to update programmatically since it's a basic redirect
echo "Updating Arknights: Endfield..."
echo "Not necessary."

# Girls' Frontline 2
# Has specific API again for getting download links
echo "Updating Girls' Frontline 2..."
PAGE=$(curl -sSL "https://gf2-web-us-api.sunborngame.com/website/url_manage?channel=gw")
GFL2=$(echo $PAGE | jq -r ".data[] | select(.type==5).Url") 
sed -i "s@http.*gf2-us.*exe@$GFL2@" ./home/profiles/gaming.nix
echo "Done!"

# LR2oraja-EndlessDream
# Managed by flake
echo "Updating LR2oraja-EndlessDream..."
echo "Not necessary."
