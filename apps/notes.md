# Apps

NOTE: relative paths are not allowed. But can use subshell to use enviroment variables.

ex: `Exec=sh -c '"$HOME"/bin/MyApp*.AppImage %U'`

Copy from:

* `/usr/share/applications/`
* `/usr/local/share/applications/`

User specific:

* `~/.local/share/applications/`

Make changes take effect:

```sh
update-desktop-database "$HOME/.local/share/applications/"
```

## Testing 

```shell
desktop-file-validate file.deskop
gio launch file.desktop 
```


## Flags

* `--ozone-platform-hint=auto` sets auto wayland/X11
* `--enable-features=VaapiVideoEncoder` Video Encode: Hardware accelerated
* `--enable-features=VaapiVideoDecode` does not seem to be needed anymore. (06-07-2024)
* `--enable-features=WebRTCPipeWireCapturer` allow using pipewire for wayland screen share. Does not seem needed anymore (06-07-2024)