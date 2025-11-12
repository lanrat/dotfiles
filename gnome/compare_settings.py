#!/usr/bin/env python3
"""
Compare GNOME dconf settings paths between current system and settings.ini
"""

import configparser
import subprocess
import sys
from pathlib import Path


def load_config(content: str) -> configparser.ConfigParser:
    """Parse INI-style content into ConfigParser"""
    config = configparser.ConfigParser()
    config.optionxform = str  # Preserve case
    config.read_string(content)
    return config


def should_ignore(path: str, ignored_paths: set) -> bool:
    """Check if path should be ignored (exact match or prefix)"""
    if path in ignored_paths:
        return True
    return any(path.startswith(ign + '/') for ign in ignored_paths)


def compare_section_values(section: str, system_config: configparser.ConfigParser,
                          settings_config: configparser.ConfigParser):
    """
    Compare key/values within a section

    Returns:
        Tuple of (keys_only_in_settings, keys_only_in_system, keys_with_diff_values)
        where keys_with_diff_values is a dict of {key: (settings_val, system_val)}
    """
    system_items = dict(system_config.items(section))
    settings_items = dict(settings_config.items(section))

    system_keys = set(system_items.keys())
    settings_keys = set(settings_items.keys())

    only_in_settings = settings_keys - system_keys
    only_in_system = system_keys - settings_keys
    common_keys = settings_keys & system_keys

    diff_values = {}
    for key in common_keys:
        if system_items[key] != settings_items[key]:
            diff_values[key] = (settings_items[key], system_items[key])

    return only_in_settings, only_in_system, diff_values


def main():
    script_dir = Path(__file__).parent

    # Load settings.ini
    settings_file = script_dir / 'settings.ini'
    if not settings_file.exists():
        print(f"Error: {settings_file} not found", file=sys.stderr)
        sys.exit(1)

    settings_config = load_config(settings_file.read_text())

    # Get current system settings
    print("Fetching current system settings...", file=sys.stderr)
    try:
        result = subprocess.run(['dconf', 'dump', '/'],
                              capture_output=True, text=True, check=True)
        system_config = load_config(result.stdout)
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error running dconf: {e}", file=sys.stderr)
        sys.exit(1)

    # Load ignored paths
    ignored_file = script_dir / 'ingored_paths.txt'
    ignored = set()
    if ignored_file.exists():
        ignored = {line.strip().rstrip('/')
                  for line in ignored_file.read_text().splitlines()
                  if line.strip() and not line.startswith('#')}

    # Check for configuration errors: paths in settings.ini that are ignored
    all_settings_paths = set(settings_config.sections())
    ignored_settings = {s for s in all_settings_paths if should_ignore(s, ignored)}

    if ignored_settings:
        print("\n⚠ WARNING: The following paths are in settings.ini but are also ignored:", file=sys.stderr)
        for path in sorted(ignored_settings):
            print(f"  ! {path}", file=sys.stderr)
        print("  These should either be removed from settings.ini or from ignored_paths.txt\n", file=sys.stderr)

    # Get and filter paths
    system_paths = {s for s in system_config.sections() if not should_ignore(s, ignored)}
    settings_paths = {s for s in all_settings_paths if not should_ignore(s, ignored)}

    # Calculate differences
    only_in_system = system_paths - settings_paths
    only_in_settings = settings_paths - system_paths
    in_both = system_paths & settings_paths

    # Print results
    print("\n" + "=" * 70)
    print("GNOME Settings Path Comparison")
    print("=" * 70)
    print(f"\nSystem paths: {len(system_paths)}")
    print(f"Settings.ini paths: {len(settings_paths)}")
    print(f"Common paths: {len(in_both)}")
    print(f"Ignored: {len(ignored)}")

    if only_in_settings:
        print(f"\n{'=' * 70}")
        print(f"In settings.ini but NOT in system ({len(only_in_settings)}):")
        print("=" * 70)
        for path in sorted(only_in_settings):
            print(f"  - {path}")

    if only_in_system:
        print(f"\n{'=' * 70}")
        print(f"In system but NOT in settings.ini ({len(only_in_system)}):")
        print("=" * 70)
        for path in sorted(only_in_system):
            print(f"  + {path}")

    if not only_in_settings and not only_in_system:
        print("\n✓ All paths match!")

    # Compare values for common paths
    if in_both:
        print(f"\n{'=' * 70}")
        print(f"Value Comparison for Common Paths ({len(in_both)} paths)")
        print("=" * 70)

        paths_with_diffs = []
        for section in sorted(in_both):
            only_in_settings_keys, only_in_system_keys, diff_values = \
                compare_section_values(section, system_config, settings_config)

            if only_in_settings_keys or only_in_system_keys or diff_values:
                paths_with_diffs.append((section, only_in_settings_keys,
                                       only_in_system_keys, diff_values))

        if paths_with_diffs:
            for section, only_in_settings_keys, only_in_system_keys, diff_values in paths_with_diffs:
                print(f"\n[{section}]")

                if only_in_settings_keys:
                    print("  Keys in settings.ini but NOT in system:")
                    for key in sorted(only_in_settings_keys):
                        value = settings_config.get(section, key)
                        print(f"    - {key}={value}")

                if only_in_system_keys:
                    print("  Keys in system but NOT in settings.ini:")
                    for key in sorted(only_in_system_keys):
                        value = system_config.get(section, key)
                        print(f"    + {key}={value}")

                if diff_values:
                    print("  Keys with different values:")
                    for key in sorted(diff_values.keys()):
                        settings_val, system_val = diff_values[key]
                        print(f"    ~ {key}")
                        print(f"        settings.ini: {settings_val}")
                        print(f"        system:       {system_val}")
        else:
            print("\n✓ All values match for common paths!")


if __name__ == '__main__':
    main()
