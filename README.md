## Hardware Provisioning

1. Clear out any existing configuration
2. Clone repository:
```
cd /etc
sudo git clone https://github.com/esibun/nixos.git
cd nixos
```
3. Generate hardware config:
```
nixos-generate-config --show-hardware-config | sudo tee hardware-configuration.nix
```
4. Ignore hardware config changes
```
sudo git update-index --skip-worktree hardware-configuration.nix
```
5. Build flake
```
sudo nixos-rebuild switch --flake .#<hostname>
```
