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

pub const Mode = enum { input, output, alternate_function, analog };
pub const PupdMode = enum { floating, pull_down, pull_up };
pub const OutputMode = enum { open_drain, push_pull };
pub const Speed = enum { low, medium, high, very_high };

pub const InputConfig = struct {
    mode: PupdMode = .floating,
};
pub const OutputConfig = struct {
    mode: OutputMode = .push_pull,
    pupd_mode: PupdMode = .floating,
    speed: Speed = .low,
};
pub const AlternateFunctionConfig = struct {
    mode: OutputMode = .push_pull,
    pupd_mode: PupdMode = .floating,
    af_mode: u4 = 0b0000,
    speed: Speed = .low,
};
pub const AnalogConfig = struct {};
pub const Config = union(Mode) {
    input: InputConfig,
    output: OutputConfig,
    alternate_function: AlternateFunctionConfig,
    analog: AnalogConfig,
};

pub fn GpioWrapper(comptime gpio: anytype) type {
    return struct {
        regs: @TypeOf(gpio) = gpio,

        const Self = @This();

        pub fn set_mode(
            comptime self: Self,
            comptime pin: u4,
            comptime config: Config,
        ) void {
            switch (config) {
                Mode.input => |mode| {
                    self.set_mode_impl(pin, 0b00);
                    self.set_pupd_mode(pin, mode.mode);
                },
                Mode.output => |mode| {
                    self.set_mode_impl(pin, 0b01);
                    self.set_output_mode(pin, mode.mode);
                    self.set_pupd_mode(pin, mode.pupd_mode);
                    self.set_output_speed(pin, mode.speed);
                },
                Mode.alternate_function => |mode| {
                    self.set_mode_impl(pin, 0b10);
                    self.set_output_mode(pin, mode.mode);
                    self.set_pupd_mode(pin, mode.pupd_mode);
                    self.set_output_speed(pin, mode.speed);
                    self.set_af_mode(pin, mode.af_mode);
                },
                Mode.analog => {
                    self.set_mode_impl(pin, 0b11);
                    self.set_pupd_mode(pin, .floating);
                },
            }
        }

        pub fn set_mode_impl(
            comptime self: Self,
            comptime pin: u4,
            comptime moder_value: u2,
        ) void {
            const reg_name = comptime get_pin_reg_name("MODER", pin);
            self.regs.MODER.modifyByName(.{.{ reg_name, moder_value }});
        }

        pub fn set_pupd_mode(
            comptime self: Self,
            comptime pin: u4,
            comptime mode: PupdMode,
        ) void {
            const reg_name = comptime get_pin_reg_name("PUPDR", pin);
            const pupdr_value: u2 = switch (mode) {
                .floating => 0b00,
                .pull_up => 0b01,
                .pull_down => 0b10,
            };
            self.regs.PUPDR.modifyByName(.{.{ reg_name, pupdr_value }});
        }

        pub fn set_output_mode(
            comptime self: Self,
            comptime pin: u4,
            comptime mode: OutputMode,
        ) void {
            const reg_name = comptime get_pin_reg_name("OT", pin);
            const ot_value: u1 = switch (mode) {
                .push_pull => 0b0,
                .open_drain => 0b1,
            };
            self.regs.OTYPER.modifyByName(.{.{ reg_name, ot_value }});
        }

        pub fn set_output_speed(
            comptime self: Self,
            comptime pin: u4,
            comptime speed: Speed,
        ) void {
            const reg_name = comptime get_pin_reg_name("OSPEEDR", pin);
            const ospeedr_value: u2 = switch (speed) {
                .low => 0b00,
                .medium => 0b01,
                .high => 0b10,
                .very_high => 0b11,
            };
            self.regs.OSPEEDR.modifyByName(.{.{ reg_name, ospeedr_value }});
        }

        pub fn set_af_mode(
            comptime self: Self,
            comptime pin: u4,
            comptime af_mode: u4,
        ) void {
            if (pin < 8) {
                const reg_name = comptime get_pin_reg_name("AFRL", pin);
                self.regs.AFRL.modifyByName(.{.{ reg_name, af_mode }});
            } else {
                const reg_name = comptime get_pin_reg_name("AFRH", pin);
                self.regs.AFRH.modifyByName(.{.{ reg_name, af_mode }});
            }
        }

        pub fn read_input(comptime self: Self, comptime pin: u4) u1 {
            const reg_name = comptime get_pin_reg_name("IDR", pin);
            var reg = self.regs.IDR.read();
            return @field(reg, reg_name);
        }

        pub fn read_output(comptime self: Self, comptime pin: u4) u1 {
            const reg_name = comptime get_pin_reg_name("ODR", pin);
            var reg = self.regs.ODR.read();
            return @field(reg, reg_name);
        }

        fn get_pin_reg_name(
            comptime reg_base: []const u8,
            comptime pin: u4,
        ) *const [std.fmt.count("{s}{}", .{ reg_base, pin }):0]u8 {
            return std.fmt.comptimePrint("{s}{}", .{ reg_base, pin });
        }
    };
}
