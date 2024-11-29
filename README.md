## Hardware Provisioning

1. Clear out any existing configuration
2. Clone repository:
```
cd /etc
sudo git clone https://github.com/esibun/nixos.git
cd nixos
```
3. Generate hardware config, remove autogenerated:
```
sudo nixos-generate-config
sudo rm configuration.nix
```
4. Procure secrets.nix:
```
sudo scp <path/to/>secrets.nix .
```
5. Add both files to git index so Nix can see them:
```
sudo git add --intent-to-add hardware-configuration.nix
sudo git update-index --assume-unchanged hardware-configuration.nix
sudo git add --intent-to-add secrets.nix
sudo git update-index --assume-unchanged secrets.nix
```
6. Build flake
```
sudo nixos-rebuild switch --flake .#<hostname>
```
