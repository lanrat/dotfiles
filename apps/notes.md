# Apps

Copy from:

* `/usr/share/applications/`
* `/usr/local/share/applications/`

User specific:

* `~/.local/share/applications/`

Make changes take effect:

```sh
update-desktop-database "$HOME/.local/share/applications/"
```


## Flags

* `--ozone-platform-hint=auto` sets auto wayland/X11
* `--enable-features=VaapiVideoEncoder` Video Encode: Hardware accelerated
* `--enable-features=VaapiVideoDecode` does not seem to be needed anymore. (06-07-2024)
* `--enable-features=WebRTCPipeWireCapturer` allow using pipewire for wayland screen share. Does not seem needed anymore (06-07-2024)