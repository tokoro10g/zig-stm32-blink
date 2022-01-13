const std = @import("std");
const regs = @import("registers.zig");

pub const port = struct {
    pub const a = GpioWrapper(regs.GPIOA){};
    pub const b = GpioWrapper(regs.GPIOB){};
    pub const c = GpioWrapper(regs.GPIOC){};
    pub const d = GpioWrapper(regs.GPIOD){};
    pub const e = GpioWrapper(regs.GPIOE){};
    pub const f = GpioWrapper(regs.GPIOF){};
    pub const g = GpioWrapper(regs.GPIOG){};
    pub const h = GpioWrapper(regs.GPIOH){};
    pub const i = GpioWrapper(regs.GPIOI){};
    pub const j = GpioWrapper(regs.GPIOJ){};
    pub const k = GpioWrapper(regs.GPIOK){};
};

pub const Direction = enum { input, output };
pub const InputMode = enum { floating, pull_down, pull_up, open_drain };
pub const OutputMode = enum { open_drain, push_pull };
pub const Speed = enum { low, medium, high, very_high };

pub const InputConfig = struct { mode: InputMode };
pub const OutputConfig = struct { mode: OutputMode, speed: Speed };
const Config = union(Direction) {
    input: InputConfig,
    output: OutputConfig,
};

pub fn GpioWrapper(comptime gpio: anytype) type {
    return struct {
        gpio: @TypeOf(gpio) = gpio,
        const Self = @This();
        pub fn set_mode(comptime self: Self, comptime pin: u4, comptime config: Config) void {
            const pin_name = "MODER" ++ std.fmt.comptimePrint("{}", .{pin});
            const moder_value: u2 = switch (config) {
                Direction.input => 0b10,
                Direction.output => 0b01,
            };
            self.gpio.MODER.modifyByName(.{.{ pin_name, moder_value }});
        }
    };
}
