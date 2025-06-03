#!/usr/bin/env python3

import argparse
import sys

from dataclasses import dataclass, field
from typing import NamedTuple, Any, Optional
from types import ModuleType
from gi.repository import GLib, Gio  # type: ignore
from enum import Enum, Flag

argcomplete: Optional[ModuleType] = None
BaseCompleter: Any
try:
    import argcomplete
    from argcomplete.completers import BaseCompleter
except ModuleNotFoundError:
    BaseCompleter = object

NAME = "org.gnome.Mutter.DisplayConfig"
INTERFACE = "org.gnome.Mutter.DisplayConfig"
OBJECT_PATH = "/org/gnome/Mutter/DisplayConfig"


class Dimension(NamedTuple):
    width: int
    height: int

    def __str__(self):
        return f"{self.width}x{self.height}"


class Position(NamedTuple):
    x: int | None
    y: int | None

    def __str__(self):
        return f"({self.x}, {self.y})"


class NamedEnum(Enum):
    def __str__(self):
        return next(
            string for enum, string in type(self).enum_names() if enum == self
        )

    @classmethod
    def from_string(cls, string):
        return next(
            enum
            for enum, enum_string in cls.enum_names()
            if string == enum_string
        )

    @classmethod
    def maybe_from_string(cls, string):
        if string:
            return next(
                enum
                for enum, enum_string in cls.enum_names()
                if string == enum_string
            )
        else:
            return None


class Transform(NamedEnum):
    NORMAL = 0
    ROTATE_90 = 1
    ROTATE_180 = 2
    ROTATE_270 = 3
    FLIPPED = 4
    ROTATE_90_FLIPPED = 5
    ROTATE_270_FLIPPED = 6
    ROTATE_180_FLIPPED = 7

    @classmethod
    def enum_names(cls):
        return [
            (Transform.NORMAL, "normal"),
            (Transform.ROTATE_90, "90"),
            (Transform.ROTATE_180, "180"),
            (Transform.ROTATE_270, "270"),
            (Transform.FLIPPED, "flipped"),
            (Transform.ROTATE_90_FLIPPED, "flipped-90"),
            (Transform.ROTATE_180_FLIPPED, "flipped-180"),
            (Transform.ROTATE_270_FLIPPED, "flipped-270"),
        ]


class LayoutMode(NamedEnum):
    LOGICAL = 1
    PHYSICAL = 2
    GLOBAL_UI_LOGICAL = 3

    @classmethod
    def enum_names(cls):
        return [
            (LayoutMode.LOGICAL, "logical"),
            (LayoutMode.PHYSICAL, "physical"),
            (LayoutMode.GLOBAL_UI_LOGICAL, "global-ui-logical"),
        ]


class ColorMode(NamedEnum):
    DEFAULT = 0
    BT2100 = 1

    @classmethod
    def enum_names(cls):
        return [
            (ColorMode.DEFAULT, "default"),
            (ColorMode.BT2100, "bt2100"),
        ]


class ConfigMethod(Enum):
    VERIFY = 0
    TEMPORARY = 1
    PERSISTENT = 2


def translate_property(name, value):
    enum_properties = {
        "layout-mode": LayoutMode,
        "color-mode": ColorMode,
        "supported-color-modes": ColorMode,
    }

    if name in enum_properties:
        if isinstance(value, list):
            return [enum_properties[name](element) for element in value]
        else:
            return enum_properties[name](value)
    else:
        return value


def translate_properties(variant):
    return {
        key: translate_property(key, value) for key, value in variant.items()
    }


def print_data(*, level: int, is_last: bool, lines: list[int], data: str):
    if is_last:
        link = "└"
    else:
        link = "├"
    padding = " "

    if level >= 0:
        indent = level
        buffer = list(f"{link:{padding}>{indent * 4}}──{data}")
        for line in lines:
            if line == level:
                continue
            index = line * 4
            if line > 0:
                index -= 1
            buffer[index] = "│"
    else:
        buffer = list(data)

    print("".join(buffer))

    if is_last and level in lines:
        lines.remove(level)
    elif not is_last and level not in lines:
        lines.append(level)


def print_properties(*, level, lines, properties):
    property_keys = list(properties.keys())

    print_data(
        level=level,
        is_last=True,
        lines=lines,
        data=f"Properties: ({len(property_keys)})",
    )
    for key in property_keys:
        is_last = key == property_keys[-1]

        value = properties[key]
        if isinstance(value, list):
            elements_string = ", ".join([str(element) for element in value])
            value_string = f"[{elements_string}]"
        elif isinstance(value, bool):
            value_string = "yes" if value else "no"
        else:
            value_string = str(value)

        print_data(
            level=level + 1,
            is_last=is_last,
            lines=lines,
            data=f"{key} ⇒  {value_string}",
        )


def print_monitor_prefs(
    display_config, monitor, level: int, lines: list[int], is_last: bool
):
    print_data(
        level=level,
        is_last=is_last,
        lines=lines,
        data="Preferences:",
    )

    print_data(
        level=level + 1,
        is_last=True,
        lines=lines,
        data="Luminances:",
    )

    for color_mode in monitor.supported_color_modes:
        (output_luminance, is_unset) = display_config.get_luminance(
            monitor, color_mode
        )
        is_last = color_mode == monitor.supported_color_modes[-1]

        is_default_string = " (default)" if is_unset else ""
        is_current_string = (
            " (current)" if monitor.color_mode == color_mode else ""
        )
        print_data(
            level=level + 2,
            is_last=is_last,
            lines=lines,
            data=f"{color_mode} ⇒  {output_luminance}{is_default_string}{is_current_string}",
        )


def strip_dbus_error_prefix(message):
    if message.startswith("GDBus.Error"):
        return message.partition(" ")[2]
    else:
        return message


def transform_size(size: Dimension, transform) -> Dimension:
    match transform:
        case (
            Transform.NORMAL
            | Transform.ROTATE_180
            | Transform.FLIPPED
            | Transform.ROTATE_180_FLIPPED
        ):
            return size
        case (
            Transform.ROTATE_90
            | Transform.ROTATE_270
            | Transform.ROTATE_90_FLIPPED
            | Transform.ROTATE_270_FLIPPED
        ):
            width, height = size
            return Dimension(height, width)
        case _:
            raise NotImplementedError


def scale_size(size: Dimension, scale) -> Dimension:
    width, height = size
    return Dimension(round(width / scale), round(height / scale))


class DisplayConfig:
    STATE_VARIANT_TYPE = GLib.VariantType.new(
        "(ua((ssss)a(siiddada{sv})a{sv})a(iiduba(ssss)a{sv})a{sv})"
    )

    def __init__(self):
        self._proxy = Gio.DBusProxy.new_for_bus_sync(
            bus_type=Gio.BusType.SESSION,
            flags=Gio.DBusProxyFlags.NONE,
            info=None,
            name=NAME,
            object_path=OBJECT_PATH,
            interface_name=INTERFACE,
            cancellable=None,
        )

    def get_current_state(self) -> GLib.Variant:
        variant = self._proxy.call_sync(
            method_name="GetCurrentState",
            parameters=None,
            flags=Gio.DBusCallFlags.NO_AUTO_START,
            timeout_msec=-1,
            cancellable=None,
        )
        assert variant.get_type().equal(self.STATE_VARIANT_TYPE)
        return variant

    def apply_monitors_config(self, config, config_method):
        serial = config.monitors_state.server_serial
        logical_monitors = config.generate_logical_monitor_tuples()
        monitors_for_lease = config.generate_monitors_for_lease_tuples()
        properties = {}

        if monitors_state.supports_changing_layout_mode:
            properties["layout-mode"] = GLib.Variant(
                "u", config.layout_mode.value
            )

        if monitors_for_lease:
            properties["monitors-for-lease"] = GLib.Variant(
                "a(ssss)", monitors_for_lease
            )

        parameters = GLib.Variant(
            "(uua(iiduba(ssa{sv}))a{sv})",
            (
                serial,
                config_method.value,
                logical_monitors,
                properties,
            ),
        )
        self._proxy.call_sync(
            method_name="ApplyMonitorsConfig",
            parameters=parameters,
            flags=Gio.DBusCallFlags.NO_AUTO_START,
            timeout_msec=-1,
            cancellable=None,
        )

    def get_luminance(self, monitor, color_mode) -> tuple[float, bool]:
        variant = self._proxy.get_cached_property("Luminance")

        luminance_entry = next(
            entry
            for entry in variant
            if entry["connector"] == monitor.connector
            and ColorMode(entry["color-mode"]) == color_mode
        )
        output_luminance = luminance_entry["luminance"]
        is_unset = luminance_entry["is-unset"]

        return (output_luminance, is_unset)

    def set_luminance(self, monitor, color_mode, luminance):
        parameters = GLib.Variant(
            "(sud)",
            (
                monitor.connector,
                color_mode.value,
                luminance,
            ),
        )
        self._proxy.call_sync(
            method_name="SetLuminance",
            parameters=parameters,
            flags=Gio.DBusCallFlags.NO_AUTO_START,
            timeout_msec=-1,
            cancellable=None,
        )

    def reset_luminance(self, monitor, color_mode):
        parameters = GLib.Variant(
            "(su)",
            (monitor.connector, color_mode.value),
        )
        self._proxy.call_sync(
            method_name="ResetLuminance",
            parameters=parameters,
            flags=Gio.DBusCallFlags.NO_AUTO_START,
            timeout_msec=-1,
            cancellable=None,
        )


@dataclass
class MonitorMode:
    name: str
    resolution: Dimension
    refresh_rate: float
    preferred_scale: float
    supported_scales: list[float]
    properties: dict

    @classmethod
    def from_variant(cls, variant):
        return cls(
            name=variant[0],
            resolution=Dimension(variant[1], variant[2]),
            refresh_rate=variant[3],
            preferred_scale=variant[4],
            supported_scales=variant[5],
            properties=translate_properties(variant[6]),
        )


@dataclass
class Monitor:
    connector: str
    vendor: str
    product: str
    display_name: str
    serial: str
    modes: list[MonitorMode]
    properties: dict
    current_mode: MonitorMode | None
    preferred_mode: MonitorMode | None
    color_mode: ColorMode | None
    supported_color_modes: list[ColorMode]

    @classmethod
    def from_variant(cls, variant):
        spec = variant[0]
        connector = spec[0]
        vendor = spec[1] if spec[1] != "" else None
        product = spec[2] if spec[2] != "" else None
        serial = spec[3] if spec[3] != "" else None
        modes = [
            MonitorMode.from_variant(mode_variant)
            for mode_variant in variant[1]
        ]
        properties = translate_properties(variant[2])

        current_mode = next(
            (mode for mode in modes if "is-current" in mode.properties),
            None,
        )
        preferred_mode = next(
            (mode for mode in modes if "is-preferred" in mode.properties),
            None,
        )

        display_name = properties.get("display-name", None)
        color_mode = properties.get("color-mode", None)
        supported_color_modes = properties.get("supported-color-modes")

        return cls(
            connector=connector,
            vendor=vendor,
            product=product,
            serial=serial,
            modes=modes,
            properties=properties,
            current_mode=current_mode,
            preferred_mode=preferred_mode,
            display_name=display_name,
            color_mode=color_mode,
            supported_color_modes=supported_color_modes,
        )


@dataclass
class LogicalMonitor:
    monitors: list[Monitor]
    scale: float
    position: Position = Position(0, 0)
    transform: Transform = Transform.NORMAL
    is_primary: bool = False
    properties: dict[str, Any] = field(default_factory=dict)
    args: dict[str, Any] = field(default_factory=dict)

    @classmethod
    def from_variant(cls, monitors_state, variant):
        position = (variant[0], variant[1])
        scale = variant[2]
        transform = Transform(variant[3])
        is_primary = variant[4]
        connectors = [connector for connector, _, _, _ in variant[5]]
        monitors = [
            monitors_state.monitors[connector] for connector in connectors
        ]
        properties = translate_properties(variant[6])

        return cls(
            monitors=monitors,
            position=position,
            scale=scale,
            transform=transform,
            is_primary=is_primary,
            properties=properties,
        )

    def calculate_size(self, layout_mode):
        mode = next(monitor.mode for monitor in self.monitors)
        size = transform_size(mode.resolution, self.transform)
        match layout_mode:
            case LayoutMode.LOGICAL:
                return scale_size(size, self.scale)
            case LayoutMode.PHYSICAL:
                return size

    def calculate_right_edge(self, layout_mode):
        x, _ = self.position
        width, _ = self.calculate_size(layout_mode)
        return x + width

    def calculate_bottom_edge(self, layout_mode):
        _, y = self.position
        _, height = self.calculate_size(layout_mode)
        return y + height


def find_closest_scale(mode, scale) -> float:
    @dataclass
    class Scale:
        scale: float
        distance: float

    best: Scale | None = None
    for supported_scale in mode.supported_scales:
        scale_distance = abs(scale - supported_scale)

        if scale_distance > 0.1:
            continue

        if not best or scale_distance < best.distance:
            best = Scale(supported_scale, scale_distance)

    if not best:
        raise ValueError(f"Scale {scale} not supported by mode")

    return best.scale


def count_keys(dictionary, keys):
    in_both = set(keys) & set(dictionary)
    return len(in_both)


def place_right_of(
    logical_monitor: LogicalMonitor,
    monitor_mappings: dict,
    layout_mode: LayoutMode,
    connector: str,
    set_y_position: bool,
):
    connector_logical_monitor = monitor_mappings[connector]
    if not connector_logical_monitor.position:
        raise ValueError(
            f"Logical monitor position configured before {connector} "
        )

    x = connector_logical_monitor.calculate_right_edge(layout_mode)
    if set_y_position:
        _, y = connector_logical_monitor.position
    else:
        y = None

    logical_monitor.position = Position(x, y)


def place_left_of(
    logical_monitor: LogicalMonitor,
    monitor_mappings: dict,
    layout_mode: LayoutMode,
    connector: str,
    set_y_position: bool,
):
    connector_logical_monitor = monitor_mappings[connector]
    if not connector_logical_monitor.position:
        raise ValueError(
            f"Logical monitor position configured before {connector} "
        )

    width, _ = logical_monitor.calculate_size(layout_mode)
    left_edge, _ = connector_logical_monitor.position
    x = left_edge - width

    if set_y_position:
        _, y = connector_logical_monitor.position
    else:
        y = None

    logical_monitor.position = Position(x, y)


def place_below(
    logical_monitor: LogicalMonitor,
    monitor_mappings: dict,
    layout_mode: LayoutMode,
    connector: str,
    set_x_position: bool,
):
    connector_logical_monitor = monitor_mappings[connector]
    if not connector_logical_monitor.position:
        raise ValueError(
            f"Logical monitor position configured before {connector} "
        )

    y = connector_logical_monitor.calculate_bottom_edge(layout_mode)
    if set_x_position:
        x, _ = connector_logical_monitor.position
    else:
        x = logical_monitor.position.x

    logical_monitor.position = Position(x, y)


def place_above(
    logical_monitor: LogicalMonitor,
    monitor_mappings: dict,
    layout_mode: LayoutMode,
    connector: str,
    set_x_position: bool,
):
    connector_logical_monitor = monitor_mappings[connector]
    if not connector_logical_monitor.position:
        raise ValueError(
            f"Logical monitor position configured before {connector} "
        )

    _, height = logical_monitor.calculate_size(layout_mode)
    _, top_edge = connector_logical_monitor.position
    y = top_edge - height

    if set_x_position:
        x, _ = connector_logical_monitor.position
    else:
        x = logical_monitor.position.x

    logical_monitor.position = Position(x, y)


class PositionType(Flag):
    NONE = 0
    ABSOLUTE_X = 1 << 0
    RELATIVE_X = 1 << 1
    ABSOLUTE_Y = 1 << 2
    RELATIVE_Y = 1 << 3


def calculate_position(
    logical_monitor: LogicalMonitor,
    layout_mode: LayoutMode,
    monitor_mappings: dict,
):
    horizontal_args = count_keys(
        logical_monitor.args, ["right_of", "left_of", "x"]
    )
    vertical_args = count_keys(logical_monitor.args, ["above", "below", "y"])

    if horizontal_args > 1:
        raise ValueError("Multiple horizontal placement instructions used")
    if vertical_args > 1:
        raise ValueError("Multiple vertical placement instructions used")

    position_types = PositionType.NONE

    set_y_position = vertical_args == 0

    x = None
    y = None

    if "x" in logical_monitor.args:
        x = int(logical_monitor.args["x"])
        y = 0 if set_y_position else None
        logical_monitor.position = Position(x, y)
        position_types |= PositionType.ABSOLUTE_X
    elif "right_of" in logical_monitor.args:
        connector = logical_monitor.args["right_of"]
        if connector not in monitor_mappings:
            raise ValueError(
                f"Invalid connector {connector} passed to --right-of"
            )
        place_right_of(
            logical_monitor,
            monitor_mappings,
            layout_mode,
            connector,
            set_y_position,
        )
        position_types |= PositionType.RELATIVE_X
    elif "left_of" in logical_monitor.args:
        connector = logical_monitor.args["left_of"]
        if connector not in monitor_mappings:
            raise ValueError(
                f"Invalid connector {connector} passed to --left-of"
            )
        place_left_of(
            logical_monitor,
            monitor_mappings,
            layout_mode,
            connector,
            set_y_position,
        )
        position_types |= PositionType.RELATIVE_X
    else:
        logical_monitor.position = Position(0, 0)

    set_x_position = horizontal_args == 0

    if "y" in logical_monitor.args:
        y = int(logical_monitor.args["y"])
        x = 0 if set_x_position else logical_monitor.position.x
        logical_monitor.position = Position(x, y)
        position_types |= PositionType.ABSOLUTE_Y
    elif "below" in logical_monitor.args:
        connector = logical_monitor.args["below"]
        if connector not in monitor_mappings:
            raise ValueError(f"Invalid connector {connector} passed to --below")
        place_below(
            logical_monitor,
            monitor_mappings,
            layout_mode,
            connector,
            set_x_position,
        )
        position_types |= PositionType.RELATIVE_Y
    elif "above" in logical_monitor.args:
        connector = logical_monitor.args["above"]
        if connector not in monitor_mappings:
            raise ValueError(f"Invalid connector {connector} passed to --above")
        place_above(
            logical_monitor,
            monitor_mappings,
            layout_mode,
            connector,
            set_x_position,
        )
        position_types |= PositionType.RELATIVE_Y
    else:
        x, y = logical_monitor.position
        if not y:
            y = 0
        logical_monitor.position = Position(x, y)

    assert logical_monitor.position.x is not None
    assert logical_monitor.position.y is not None

    return position_types


def align_horizontally(logical_monitors: list[LogicalMonitor]):
    min_x = min(
        logical_monitor.position.x
        for logical_monitor in logical_monitors
        if logical_monitor.position.x is not None
    )

    dx = min_x
    if dx == 0:
        return

    for logical_monitor in logical_monitors:
        x, y = logical_monitor.position
        logical_monitor.position = Position(
            x - dx if x is not None else None, y
        )


def align_vertically(logical_monitors: list[LogicalMonitor]):
    min_y = min(
        logical_monitor.position.y
        for logical_monitor in logical_monitors
        if logical_monitor.position.y is not None
    )

    dy = min_y
    if dy == 0:
        return

    for logical_monitor in logical_monitors:
        x, y = logical_monitor.position
        logical_monitor.position = Position(
            x, y - dy if y is not None else None
        )


def calculate_positions(
    logical_monitors: list[LogicalMonitor],
    layout_mode: LayoutMode,
    monitor_mappings: dict,
):
    position_types = PositionType.NONE
    for logical_monitor in logical_monitors:
        position_types |= calculate_position(
            logical_monitor, layout_mode, monitor_mappings
        )

    if not position_types & PositionType.ABSOLUTE_X:
        align_horizontally(logical_monitors)
    if not position_types & PositionType.ABSOLUTE_Y:
        align_vertically(logical_monitors)


def create_logical_monitor(monitors_state, layout_mode, logical_monitor_args):
    if "monitors" not in logical_monitor_args:
        raise ValueError("Logical monitor empty")
    monitors_arg = logical_monitor_args["monitors"]

    scale = logical_monitor_args.get("scale", None)
    is_primary = logical_monitor_args.get("primary", False)
    transform = Transform.from_string(
        logical_monitor_args.get("transform", "normal")
    )

    monitors = []

    common_mode_resolution = None

    for monitor_args in monitors_arg:
        (connector,) = monitor_args["key"]
        if connector not in monitors_state.monitors:
            raise ValueError(f"Monitor {connector} not found")
        monitor = monitors_state.monitors[connector]

        mode_name = monitor_args.get("mode", None)
        if mode_name:
            mode = next(
                (mode for mode in monitor.modes if mode.name == mode_name), None
            )
            if not mode:
                raise ValueError(
                    f"No mode {mode_name} available for {connector}"
                )
        else:
            mode = monitor.preferred_mode

        if not common_mode_resolution:
            common_mode_resolution = mode.resolution

            if not scale:
                scale = mode.preferred_scale
            else:
                scale = find_closest_scale(mode, scale)
        else:
            mode_width, mode_height = mode.resolution
            common_mode_width, common_mode_height = common_mode_resolution
            if (
                mode_width != common_mode_width
                or mode_height != common_mode_height
            ):
                raise ValueError(
                    "Different monitor resolutions within the same logical monitor"
                )

        monitor.mode = mode
        monitor.color_mode = ColorMode.maybe_from_string(
            monitor_args.get("color_mode", None)
        )

        monitors.append(monitor)

    return LogicalMonitor(
        monitors=monitors,
        scale=scale,
        is_primary=is_primary,
        transform=transform,
        position=None,
        args=logical_monitor_args,
    )


def generate_configuration(monitors_state, args):
    layout_mode_str = args.layout_mode
    if not layout_mode_str:
        layout_mode = monitors_state.layout_mode
    else:
        if not monitors_state.supports_changing_layout_mode:
            raise ValueError(
                "Configuring layout mode not supported by the server"
            )
        layout_mode = LayoutMode.from_string(layout_mode_str)

    logical_monitors = []
    monitor_mappings = {}
    for logical_monitor_args in args.logical_monitors:
        logical_monitor = create_logical_monitor(
            monitors_state, layout_mode, logical_monitor_args
        )
        logical_monitors.append(logical_monitor)
        for monitor in logical_monitor.monitors:
            monitor_mappings[monitor.connector] = logical_monitor

    monitors_for_lease = []
    for connector in args.monitors_for_lease:
        monitors_for_lease.append(monitors_state.monitors[connector])

    calculate_positions(logical_monitors, layout_mode, monitor_mappings)

    return Config(
        monitors_state, logical_monitors, layout_mode, monitors_for_lease
    )


def derive_config_method(args):
    if args.persistent and args.verify:
        raise ValueError(
            "Configuration can't be both persistent and verify-only"
        )
    if args.persistent:
        return ConfigMethod.PERSISTENT
    elif args.verify:
        return ConfigMethod.VERIFY
    else:
        return ConfigMethod.TEMPORARY


def print_config(config):
    print("Configuration:")
    lines = []

    print_data(
        level=0,
        is_last=False,
        lines=lines,
        data=f"Layout mode: {config.layout_mode}",
    )

    print_data(
        level=0,
        is_last=False,
        lines=lines,
        data=f"Logical monitors ({len(config.logical_monitors)})",
    )

    index = 1
    for logical_monitor in config.logical_monitors:
        is_last = logical_monitor == config.logical_monitors[-1]
        print_data(
            level=1,
            is_last=is_last,
            lines=lines,
            data=f"Logical monitor #{index}",
        )

        print_data(
            level=2,
            is_last=False,
            lines=lines,
            data=f"Position: {logical_monitor.position}",
        )
        print_data(
            level=2,
            is_last=False,
            lines=lines,
            data=f"Scale: {logical_monitor.scale}",
        )
        print_data(
            level=2,
            is_last=False,
            lines=lines,
            data=f"Transform: {logical_monitor.transform}",
        )
        print_data(
            level=2,
            is_last=False,
            lines=lines,
            data=f"Primary: {'yes' if logical_monitor.is_primary else 'no'}",
        )

        print_data(
            level=2,
            is_last=True,
            lines=lines,
            data=f"Monitors: ({len(logical_monitor.monitors)})",
        )
        for monitor in logical_monitor.monitors:
            is_last = monitor == logical_monitor.monitors[-1]
            print_data(
                level=3,
                is_last=is_last,
                lines=lines,
                data=f"Monitor {monitor.connector} ({monitor.display_name})",
            )
            print_data(
                level=4,
                is_last=not monitor.color_mode,
                lines=lines,
                data=f"Mode: {monitor.mode.name}",
            )
            if monitor.color_mode:
                print_data(
                    level=4,
                    is_last=True,
                    lines=lines,
                    data=f"Color mode: {monitor.color_mode}",
                )

        index += 1

    print_data(
        level=0,
        is_last=True,
        lines=lines,
        data=f"Monitors for lease ({len(config.monitors_for_lease)})",
    )

    for monitor in config.monitors_for_lease:
        is_last = monitor == config.monitors_for_lease[-1]
        print_data(
            level=1,
            is_last=is_last,
            lines=lines,
            data=f"Monitor {monitor.connector} ({monitor.display_name})",
        )


class MonitorsState:
    def __init__(self, display_config):
        current_state = display_config.get_current_state()

        self.display_config = display_config
        self.server_serial = current_state[0]
        self.properties = translate_properties(current_state[3])
        self.supports_changing_layout_mode = self.properties.get(
            "supports-changing-layout-mode", False
        )
        self.layout_mode = (
            self.properties.get("layout-mode") or LayoutMode.LOGICAL
        )

        self.init_monitors(current_state)
        self.init_logical_monitors(current_state)

    def init_monitors(self, current_state):
        self.monitors = {}
        for monitor_variant in current_state[1]:
            monitor = Monitor.from_variant(monitor_variant)
            self.monitors[monitor.connector] = monitor

    def init_logical_monitors(self, current_state):
        self.logical_monitors = []
        for variant in current_state[2]:
            logical_monitor = LogicalMonitor.from_variant(self, variant)
            self.logical_monitors.append(logical_monitor)

    def create_current_config(self):
        return Config.create_current(self)

    def print_mode(self, mode, is_last, show_properties, lines):
        print_data(level=2, is_last=is_last, lines=lines, data=f"{mode.name}")

        if not show_properties:
            return

        print_data(
            level=3,
            is_last=False,
            lines=lines,
            data=f"Dimension: {mode.resolution}",
        )
        print_data(
            level=3,
            is_last=False,
            lines=lines,
            data=f"Refresh rate: {mode.refresh_rate:.3f}",
        )
        print_data(
            level=3,
            is_last=False,
            lines=lines,
            data=f"Preferred scale: {mode.preferred_scale}",
        )
        print_data(
            level=3,
            is_last=False,
            lines=lines,
            data=f"Supported scales: {mode.supported_scales}",
        )

        if show_properties:
            mode_properties = mode.properties
            print_properties(level=3, lines=lines, properties=mode_properties)

    def print_current_state(self, show_modes=False, show_properties=False):
        print("Monitors:")
        lines = []
        monitors = list(self.monitors.values())
        for monitor in monitors:
            is_last = monitor == monitors[-1]
            modes = monitor.modes
            properties = monitor.properties

            if monitor.display_name:
                monitor_title = (
                    f"Monitor {monitor.connector} ({monitor.display_name})"
                )
            else:
                monitor_title = f"Monitor {monitor.connector}"

            print_data(
                level=0,
                is_last=is_last,
                lines=lines,
                data=monitor_title,
            )

            if monitor.vendor:
                print_data(
                    level=1,
                    is_last=False,
                    lines=lines,
                    data=f"Vendor: {monitor.vendor}",
                )
            if monitor.product:
                print_data(
                    level=1,
                    is_last=False,
                    lines=lines,
                    data=f"Product: {monitor.product}",
                )
            if monitor.serial:
                print_data(
                    level=1,
                    is_last=False,
                    lines=lines,
                    data=f"Serial: {monitor.serial}",
                )

            if show_modes:
                print_data(
                    level=1,
                    is_last=not show_properties,
                    lines=lines,
                    data=f"Modes ({len(modes)})",
                )
                for mode in modes:
                    is_last = mode == modes[-1]
                    self.print_mode(mode, is_last, show_properties, lines)
            else:
                mode = next(
                    (mode for mode in modes if "is-current" in mode.properties),
                    None,
                )
                if mode:
                    mode_type = "Current"
                else:
                    mode = next(
                        (
                            mode
                            for mode in modes
                            if "is-preferred" in mode.properties
                        ),
                        None,
                    )
                    if mode:
                        mode_type = "Preferred"

                if mode:
                    print_data(
                        level=1,
                        is_last=False,
                        lines=lines,
                        data=f"{mode_type} mode",
                    )
                    self.print_mode(mode, True, show_properties, lines)

            print_monitor_prefs(
                self.display_config,
                monitor,
                level=1,
                lines=lines,
                is_last=not show_properties,
            )

            if show_properties:
                print_properties(level=1, lines=lines, properties=properties)

        print()
        print("Logical monitors:")
        index = 1
        for logical_monitor in self.logical_monitors:
            is_last = logical_monitor == self.logical_monitors[-1]
            print_data(
                level=0,
                is_last=is_last,
                lines=lines,
                data=f"Logical monitor #{index}",
            )
            (x, y) = logical_monitor.position
            print_data(
                level=1,
                is_last=False,
                lines=lines,
                data=f"Position: ({x}, {y})",
            )
            print_data(
                level=1,
                is_last=False,
                lines=lines,
                data=f"Scale: {logical_monitor.scale}",
            )
            print_data(
                level=1,
                is_last=False,
                lines=lines,
                data=f"Transform: {logical_monitor.transform}",
            )
            print_data(
                level=1,
                is_last=False,
                lines=lines,
                data=f"Primary: {'yes' if logical_monitor.is_primary else 'no'}",
            )
            monitors = logical_monitor.monitors
            print_data(
                level=1,
                is_last=not show_properties,
                lines=lines,
                data=f"Monitors: ({len(monitors)})",
            )
            for monitor in monitors:
                is_last = monitor == monitors[-1]

                if monitor.display_name:
                    monitor_title = (
                        f"{monitor.connector} ({monitor.display_name})"
                    )
                else:
                    monitor_title = f"{monitor.connector}"

                print_data(
                    level=2,
                    is_last=is_last,
                    lines=lines,
                    data=monitor_title,
                )

            if show_properties:
                properties = logical_monitor.properties
                print_properties(level=1, lines=lines, properties=properties)

            index += 1

        if show_properties:
            properties = self.properties
            print()
            print_properties(level=-1, lines=lines, properties=properties)


@dataclass
class Config:
    monitors_state: MonitorsState
    logical_monitors: list[LogicalMonitor]
    layout_mode: LayoutMode
    monitors_for_lease: Monitor

    def generate_monitor_tuples(self, monitors):
        tuples = []
        for monitor in monitors:
            options = {}
            if monitor.color_mode:
                options["color-mode"] = GLib.Variant(
                    "u", monitor.color_mode.value
                )

            # Variant type: (ssa{sv})
            tuples.append(
                (
                    monitor.connector,
                    monitor.mode.name,
                    options,
                )
            )
        return tuples

    def generate_logical_monitor_tuples(self):
        tuples = []
        for logical_monitor in self.logical_monitors:
            x, y = logical_monitor.position
            scale = logical_monitor.scale
            transform = logical_monitor.transform.value
            is_primary = logical_monitor.is_primary

            monitors = self.generate_monitor_tuples(logical_monitor.monitors)

            # Variant type: (iiduba(ssa{sv}))
            tuples.append(
                (
                    x,
                    y,
                    scale,
                    transform,
                    is_primary,
                    monitors,
                )
            )
        return tuples

    def generate_monitors_for_lease_tuples(self):
        tuples = []
        for monitor in self.monitors_for_lease:
            tuples.append(
                (
                    monitor.connector,
                    monitor.vendor,
                    monitor.product,
                    monitor.serial,
                )
            )
        return tuples


class GroupAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        if len(values) == 1:
            (value,) = values
            namespace._current_group = {
                "key": value,
            }
        else:
            namespace._current_group = {}

        groups = namespace.__dict__.setdefault(self.dest, [])
        groups.append(namespace._current_group)


class SubGroupAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        if not hasattr(namespace, "_current_group"):
            raise argparse.ArgumentError(
                self, "No current group to add sub-group to"
            )
        if self.dest not in namespace._current_group:
            namespace._current_group[self.dest] = []
        sub_group = {
            "key": values,
        }
        namespace._current_group[self.dest].append(sub_group)
        namespace._current_sub_group = sub_group


class AppendToGlobal(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        if getattr(namespace, "_current_group", None) is not None:
            raise argparse.ArgumentError(self, "Must pass during global scope")
        setattr(namespace, self.dest, self.const or values)


class AppendToGroup(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        if getattr(namespace, "_current_group", None) is None:
            raise argparse.ArgumentError(self, "No current group to add to")
        namespace._current_group[self.dest] = self.const or values


class AppendToSubGroup(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        if getattr(namespace, "_current_group", None) is None:
            raise argparse.ArgumentError(self, "No current group")
        if getattr(namespace, "_current_sub_group", None) is None:
            raise argparse.ArgumentError(self, "No current sub-group")
        namespace._current_sub_group[self.dest] = self.const or values


def clearattr(namespace, attr):
    if hasattr(namespace, attr):
        delattr(namespace, attr)


class GdctlParser(argparse.ArgumentParser):
    def parse_args(self):
        namespace = super().parse_args()
        clearattr(namespace, "_current_group")
        clearattr(namespace, "_current_sub_group")
        return namespace


class MonitorCompleter(BaseCompleter):
    def __call__(self, **kwargs):
        try:
            display_config = DisplayConfig()
            monitors_state = MonitorsState(display_config)
            return tuple(monitors_state.monitors)
        except Exception:
            return ()


class MonitorModeCompleter(BaseCompleter):
    def __call__(self, parsed_args=None, **kwargs):
        try:
            (connector,) = parsed_args._current_sub_group["key"]

            display_config = DisplayConfig()
            monitors_state = MonitorsState(display_config)

            monitor = monitors_state.monitors[connector]
            return (mode.name for mode in monitor.modes)
        except Exception:
            return ()


class ScaleCompleter(BaseCompleter):
    def __call__(self, parsed_args=None, **kwargs):
        try:
            (connector,) = parsed_args._current_sub_group["key"]

            display_config = DisplayConfig()
            monitors_state = MonitorsState(display_config)

            monitor = monitors_state.monitors[connector]

            mode = parsed_args._current_sub_group.get("mode", None)
            if not mode:
                mode = monitor.preferred_mode

            scales = mode.supported_scales
            scales.sort(key=lambda scale: abs(scale - mode.preferred_scale))

            return (repr(scale) for scale in scales)
        except Exception:
            return ()


class NamedEnumCompleter(BaseCompleter):
    def __init__(self, enum_type):
        self.enum_type = enum_type

    def __call__(self, **kwargs):
        return (str(enum_value) for enum_value in self.enum_type)


class LayoutModeCompleter(NamedEnumCompleter):
    def __init__(self):
        super().__init__(LayoutMode)


class TransformCompleter(NamedEnumCompleter):
    def __init__(self):
        super().__init__(Transform)


class ColorModeCompleter(NamedEnumCompleter):
    def __init__(self):
        super().__init__(ColorMode)


if __name__ == "__main__":
    parser = GdctlParser(
        description="Display control utility",
    )

    subparser = parser.add_subparsers(
        dest="command",
        title="The following commands are available",
        metavar="COMMAND",
        required=True,
    )
    show_parser = subparser.add_parser(
        "show", help="Show display configuration"
    )
    show_parser.add_argument(
        "-m",
        "--modes",
        action="store_true",
        help="List available monitor modes",
    )
    show_parser.add_argument(
        "-p",
        "--properties",
        action="store_true",
        help="List properties",
    )
    show_parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Display all available information",
    )
    set_parser = subparser.add_parser(
        "set",
        help="Set display configuration",
    )
    set_parser.add_argument(
        "-P",
        "--persistent",
        action=AppendToGlobal,
        const=True,
        nargs=0,
        default=False,
    )
    set_parser.add_argument(
        "-v",
        "--verbose",
        action=AppendToGlobal,
        const=True,
        nargs=0,
        default=False,
    )
    set_parser.add_argument(
        "-V",
        "--verify",
        action=AppendToGlobal,
        const=True,
        nargs=0,
        default=False,
    )
    set_parser.add_argument(
        "-l",
        "--layout-mode",
        choices=[str(layout_mode) for layout_mode in list(LayoutMode)],
        type=str,
        action=AppendToGlobal,
    ).completer = LayoutModeCompleter()  # type: ignore[attr-defined]
    set_parser.add_argument(
        "-L",
        "--logical-monitor",
        dest="logical_monitors",
        action=GroupAction,
        nargs=0,
        default=[],
    )
    set_parser.add_argument(
        "-e",
        "--for-lease-monitor",
        dest="monitors_for_lease",
        action="append",
        type=str,
        default=[],
    ).completer = MonitorCompleter()  # type: ignore[attr-defined]
    logical_monitor_parser = set_parser.add_argument_group(
        "logical_monitor",
        "Logical monitor options (pass after --logical-monitor)",
        argument_default=argparse.SUPPRESS,
    )
    logical_monitor_parser.add_argument(
        "-M",
        "--monitor",
        dest="monitors",
        metavar="CONNECTOR",
        action=SubGroupAction,
        nargs=1,
        help="Configure monitor",
    ).completer = MonitorCompleter()  # type: ignore[attr-defined]
    monitor_parser = set_parser.add_argument_group(
        "monitor",
        "Monitor options (pass after --monitor)",
        argument_default=argparse.SUPPRESS,
    )
    monitor_parser.add_argument(
        "--mode",
        "-m",
        action=AppendToSubGroup,
        help="Monitor mode",
        type=str,
    ).completer = MonitorModeCompleter()  # type: ignore[attr-defined]
    monitor_parser.add_argument(
        "--color-mode",
        "-c",
        action=AppendToSubGroup,
        help="Color mode",
        choices=[str(color_mode) for color_mode in list(ColorMode)],
        type=str,
    ).completer = ColorModeCompleter()  # type: ignore[attr-defined]
    logical_monitor_parser.add_argument(
        "--primary",
        "-p",
        action=AppendToGroup,
        help="Mark as primary",
        type=bool,
        const=True,
        nargs=0,
    )
    logical_monitor_parser.add_argument(
        "--scale",
        "-s",
        action=AppendToGroup,
        help="Logical monitor scale",
        type=float,
    ).completer = ScaleCompleter()  # type: ignore[attr-defined]
    logical_monitor_parser.add_argument(
        "--transform",
        "-t",
        action=AppendToGroup,
        help="Apply viewport transform",
        choices=[str(transform) for transform in list(Transform)],
        type=str,
    ).completer = TransformCompleter()  # type: ignore[attr-defined]
    logical_monitor_parser.add_argument(
        "--x",
        "-x",
        action=AppendToGroup,
        help="X position",
        type=int,
    )
    logical_monitor_parser.add_argument(
        "--y",
        "-y",
        action=AppendToGroup,
        help="Y position",
        type=int,
    )
    logical_monitor_parser.add_argument(
        "--right-of",
        action=AppendToGroup,
        metavar="CONNECTOR",
        help="Place right of other monitor",
        type=str,
    ).completer = MonitorCompleter()  # type: ignore[attr-defined]
    logical_monitor_parser.add_argument(
        "--left-of",
        action=AppendToGroup,
        metavar="CONNECTOR",
        help="Place left of other monitor",
        type=str,
    ).completer = MonitorCompleter()  # type: ignore[attr-defined]
    logical_monitor_parser.add_argument(
        "--above",
        action=AppendToGroup,
        metavar="CONNECTOR",
        help="Place above other monitor",
        type=str,
    ).completer = MonitorCompleter()  # type: ignore[attr-defined]
    logical_monitor_parser.add_argument(
        "--below",
        action=AppendToGroup,
        metavar="CONNECTOR",
        help="Place below other monitor",
        type=str,
    ).completer = MonitorCompleter()  # type: ignore[attr-defined]

    prefs_parser = subparser.add_parser(
        "prefs",
        help="Set display preferences",
    )
    prefs_parser.add_argument(
        "-M",
        "--monitor",
        dest="monitors",
        metavar="CONNECTOR",
        action=GroupAction,
        nargs=1,
        default=[],
        help="Change monitor preferences",
    ).completer = MonitorCompleter()  # type: ignore[attr-defined]
    monitor_prefs_parser = prefs_parser.add_argument_group(
        "monitor",
        "Monitor preferences (pass after --monitor)",
        argument_default=argparse.SUPPRESS,
    )
    monitor_prefs_parser.add_argument(
        "-l",
        "--luminance",
        action=AppendToGroup,
        type=float,
        nargs=1,
    )
    monitor_prefs_parser.add_argument(
        "--reset-luminance",
        action=AppendToGroup,
        type=bool,
        const=True,
        nargs=0,
    )

    if argcomplete:
        for action in [
            GroupAction,
            SubGroupAction,
            AppendToGroup,
            AppendToSubGroup,
            AppendToGlobal,
        ]:
            argcomplete.safe_actions.add(action)

        argcomplete.autocomplete(
            parser, default_completer=argcomplete.SuppressCompleter
        )  # type: ignore[arg-type]

    args = parser.parse_args()

    match args.command:
        case "show":
            try:
                display_config = DisplayConfig()
                monitors_state = MonitorsState(display_config)
            except GLib.Error as e:
                if e.domain == GLib.quark_to_string(Gio.DBusError.quark()):
                    error_message = strip_dbus_error_prefix(e.message)
                    print(
                        f"Failed to retrieve current state: {error_message}",
                        file=sys.stderr,
                    )
                sys.exit(1)

            if args.verbose:
                show_modes = True
                show_properties = True
            else:
                show_modes = args.modes
                show_properties = args.properties

            monitors_state.print_current_state(
                show_modes=show_modes,
                show_properties=show_properties,
            )
        case "set":
            try:
                display_config = DisplayConfig()
                monitors_state = MonitorsState(display_config)
            except GLib.Error as e:
                if e.domain == GLib.quark_to_string(Gio.DBusError.quark()):
                    error_message = strip_dbus_error_prefix(e.message)
                    print(
                        f"Failed to retrieve current state: {error_message}",
                        file=sys.stderr,
                    )
                sys.exit(1)

            try:
                config = generate_configuration(monitors_state, args)
                config_method = derive_config_method(args)
                if args.verbose:
                    print_config(config)
                display_config.apply_monitors_config(config, config_method)
            except ValueError as e:
                print(f"Failed to create configuration: {e}", file=sys.stderr)
                sys.exit(1)
            except GLib.Error as e:
                if e.domain == GLib.quark_to_string(Gio.DBusError.quark()):
                    error_message = strip_dbus_error_prefix(e.message)
                    print(
                        f"Failed to apply configuration: {error_message}",
                        file=sys.stderr,
                    )
                else:
                    print(
                        f"Failed to apply configuration: {e.message}",
                        file=sys.stderr,
                    )
                sys.exit(1)
        case "prefs":
            try:
                display_config = DisplayConfig()
                monitors_state = MonitorsState(display_config)
            except GLib.Error as e:
                if e.domain == GLib.quark_to_string(Gio.DBusError.quark()):
                    error_message = strip_dbus_error_prefix(e.message)
                    print(
                        f"Failed to retrieve current state: {error_message}",
                        file=sys.stderr,
                    )
                sys.exit(1)

            for monitor_prefs in args.monitors:
                connector = monitor_prefs["key"]

                if (
                    "luminance" in monitor_prefs
                    and "reset_luminance" in monitor_prefs
                ):
                    print(
                        "Cannot both set and reset luminance",
                        file=sys.stderr,
                    )
                    sys.exit(1)

                if connector not in monitors_state.monitors:
                    print(
                        f"Monitor with connector {connector} not found",
                        file=sys.stderr,
                    )
                    sys.exit(1)

                monitor = monitors_state.monitors[connector]

                if "luminance" in monitor_prefs:
                    (luminance,) = monitor_prefs["luminance"]
                    display_config.set_luminance(
                        monitor, monitor.color_mode, luminance
                    )
                elif "reset_luminance" in monitor_prefs:
                    display_config.reset_luminance(monitor, monitor.color_mode)
