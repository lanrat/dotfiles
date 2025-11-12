# GNOME Settings Management

## Files

- `settings.ini` - Tracked GNOME settings (created by `dconf dump /`)
- `ingored_paths.txt` - Paths to ignore during comparison
- `ignored_keys.ini` - Specific keys to ignore (device-specific settings)
- `compare_settings.py` - Compare current system settings with settings.ini

## Usage

Compare current system settings with tracked settings:

```bash
./compare_settings.py
```

The script will show:

- Paths in `settings.ini` but not on your system (missing settings)
- Paths on your system but not in `settings.ini` (untracked settings)
- Keys with different values between system and settings.ini
- Keys in system not in settings.ini (potential new settings to track)
- Warning if any paths in `settings.ini` are also ignored

Device-specific keys listed in `ignored_keys.ini` are filtered out from the comparison.

## Managing Settings

### Update tracked settings

```bash
dconf dump / > settings.ini
```

### Remove unwanted paths from system

```bash
# Remove entire section (note: requires trailing /)
dconf reset -f /org/gnome/calculator/

# Remove single key
dconf reset /org/gnome/desktop/interface/clock-show-weekday
```

### Apply tracked settings

```bash
dconf load / < settings.ini
```

### Ignore device-specific keys

Add keys to `ignored_keys.ini` that shouldn't be synced across systems:

```ini
[org/gnome/shell]
favorite-apps=
command-history=
```
