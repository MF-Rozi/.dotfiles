# Copy dnscrypt-proxy config to dotfiles

```bash
cp -rv /etc/dnscrypt-proxy ~/dotfiles/
```
# Restore dnscrypt-proxy config from dotfiles

```bash
sudo cp -rv ~/dotfiles/dnscrypt-proxy/* /etc/dnscrypt-proxy/
sudo chown root:root /etc/dnscrypt-proxy/*
sudo chmod 644 /etc/dnscrypt-proxy/*
sudo chmod 750 /etc/dnscrypt-proxy/
```

# Waydroid Management

### Disable Waydroid Autostart & Stop
```bash
systemctl --user disable --now waydroid-session.service
sudo systemctl disable --now waydroid-container.service
waydroid session stop
```

### Enable Waydroid Autostart
```bash
sudo systemctl enable --now waydroid-container.service
systemctl --user enable --now waydroid-session.service
```

### Run Waydroid Manually (On-demand)
```bash
sudo systemctl start waydroid-container.service
waydroid session start
```