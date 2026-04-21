# code-server systemd user service

```bash
systemctl --user enable --now code-server   # enable at login + start now
loginctl enable-linger lanrat               # run user services at boot without login
```

## Without linger

Services start on SSH login, stop when last session ends. A detached tmux keeps them alive. No auto-start on reboot.

## With linger

Services start at boot and persist across logouts/reboots. Affects all enabled `--user` services. Reverse with `loginctl disable-linger lanrat`.
