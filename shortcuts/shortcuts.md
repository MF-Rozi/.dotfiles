# Copy dnscrypt-proxy config to dotfiles

```bash
cp -rv /etc/dnscrypt-proxy ~/dotfiles/
```
# Restore dnscrypt-proxy config from dotfiles

```bash
sudo cp -rv ~/dotfiles/dnscrypt-proxy/* /etc/dnscrypt-proxy/
```