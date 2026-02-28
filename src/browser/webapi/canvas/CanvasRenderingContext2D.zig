// Copyright (C) 2023-2025  Lightpanda (Selecy SAS)
//
// Francis Bouvier <francis@lightpanda.io>
// Pierre Tachoire <pierre@lightpanda.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");

const js = @import("../../js/js.zig");

const color = @import("../../color.zig");
const Page = @import("../../Page.zig");

/// This class doesn't implement a `constructor`.
/// It can be obtained with a call to `HTMLCanvasElement#getContext`.
/// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D
const CanvasRenderingContext2D = @This();
/// Fill color.
/// TODO: Add support for `CanvasGradient` and `CanvasPattern`.
_fill_style: color.RGBA = color.RGBA.Named.black,
_pixels: std.AutoHashMapUnmanaged(u64, Pixel) = .{},
_font_size: f64 = 10.0,
_font_family: []const u8 = "sans-serif",

const Pixel = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

const ImageData = struct {
    data: js.TypedArray(u8),
    width: u32,
    height: u32,
};

pub fn packPixelKey(x: u32, y: u32) u64 {
    return (@as(u64, y) << 32) | @as(u64, x);
}

fn parseRgbFunction(value: []const u8) ?color.RGBA {
    if (!std.mem.startsWith(u8, value, "rgb(") or !std.mem.endsWith(u8, value, ")")) {
        return null;
    }

    const inner = std.mem.trim(u8, value[4 .. value.len - 1], " ");
    var it = std.mem.tokenizeAny(u8, inner, " ,");

    var channels: [3]u8 = undefined;
    var i: usize = 0;
    while (it.next()) |token| {
        if (i >= channels.len) return null;
        channels[i] = std.fmt.parseInt(u8, token, 10) catch return null;
        i += 1;
    }
    if (i != channels.len) return null;

    return .{ .r = channels[0], .g = channels[1], .b = channels[2], .a = 255 };
}

fn applyRect(
    self: *CanvasRenderingContext2D,
    x: f64,
    y: f64,
    width: f64,
    height: f64,
    fill_pixel: ?Pixel,
    page: *Page,
) !void {
    if (!std.math.isFinite(x) or !std.math.isFinite(y) or !std.math.isFinite(width) or !std.math.isFinite(height)) {
        return;
    }

    const max_side: f64 = 2048.0;
    const left = @max(0.0, @floor(@min(x, x + width)));
    const top = @max(0.0, @floor(@min(y, y + height)));
    const right = @min(max_side, @ceil(@max(x, x + width)));
    const bottom = @min(max_side, @ceil(@max(y, y + height)));

    if (right <= left or bottom <= top) {
        return;
    }

    const x_start: usize = @intFromFloat(left);
    const y_start: usize = @intFromFloat(top);
    const x_end: usize = @intFromFloat(right);
    const y_end: usize = @intFromFloat(bottom);

    for (y_start..y_end) |yy| {
        for (x_start..x_end) |xx| {
            const key = packPixelKey(@intCast(xx), @intCast(yy));
            if (fill_pixel) |pixel| {
                try self._pixels.put(page.arena, key, pixel);
            } else {
                _ = self._pixels.remove(key);
            }
        }
    }
}

pub fn getFillStyle(self: *const CanvasRenderingContext2D, page: *Page) ![]const u8 {
    var w = std.Io.Writer.Allocating.init(page.call_arena);
    try self._fill_style.format(&w.writer);
    return w.written();
}

pub fn setFillStyle(
    self: *CanvasRenderingContext2D,
    value: []const u8,
) !void {
    if (parseRgbFunction(value)) |rgb| {
        self._fill_style = rgb;
        return;
    }

    // Prefer the same fill_style if fails.
    self._fill_style = color.RGBA.parse(value) catch self._fill_style;
}

pub fn getGlobalAlpha(_: *const CanvasRenderingContext2D) f64 {
    return 1.0;
}

pub fn getGlobalCompositeOperation(_: *const CanvasRenderingContext2D) []const u8 {
    return "source-over";
}

pub fn getStrokeStyle(_: *const CanvasRenderingContext2D) []const u8 {
    return "#000000";
}

pub fn getLineWidth(_: *const CanvasRenderingContext2D) f64 {
    return 1.0;
}

pub fn getLineCap(_: *const CanvasRenderingContext2D) []const u8 {
    return "butt";
}

pub fn getLineJoin(_: *const CanvasRenderingContext2D) []const u8 {
    return "miter";
}

pub fn getMiterLimit(_: *const CanvasRenderingContext2D) f64 {
    return 10.0;
}

pub fn getFont(self: *const CanvasRenderingContext2D, page: *Page) ![]const u8 {
    return std.fmt.allocPrint(page.call_arena, "{d}px {s}", .{ self._font_size, self._font_family });
}

pub fn getTextAlign(_: *const CanvasRenderingContext2D) []const u8 {
    return "start";
}

pub fn getTextBaseline(_: *const CanvasRenderingContext2D) []const u8 {
    return "alphabetic";
}

pub fn save(_: *CanvasRenderingContext2D) void {}
pub fn restore(_: *CanvasRenderingContext2D) void {}
pub fn scale(_: *CanvasRenderingContext2D, _: f64, _: f64) void {}
pub fn rotate(_: *CanvasRenderingContext2D, _: f64) void {}
pub fn translate(_: *CanvasRenderingContext2D, _: f64, _: f64) void {}
pub fn transform(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64, _: f64, _: f64) void {}
pub fn setTransform(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64, _: f64, _: f64) void {}
pub fn resetTransform(_: *CanvasRenderingContext2D) void {}
pub fn setGlobalAlpha(_: *CanvasRenderingContext2D, _: f64) void {}
pub fn setGlobalCompositeOperation(_: *CanvasRenderingContext2D, _: []const u8) void {}
pub fn setStrokeStyle(_: *CanvasRenderingContext2D, _: []const u8) void {}
pub fn setLineWidth(_: *CanvasRenderingContext2D, _: f64) void {}
pub fn setLineCap(_: *CanvasRenderingContext2D, _: []const u8) void {}
pub fn setLineJoin(_: *CanvasRenderingContext2D, _: []const u8) void {}
pub fn setMiterLimit(_: *CanvasRenderingContext2D, _: f64) void {}
pub fn clearRect(self: *CanvasRenderingContext2D, x: f64, y: f64, width: f64, height: f64, page: *Page) !void {
    try self.applyRect(x, y, width, height, null, page);
}
pub fn fillRect(self: *CanvasRenderingContext2D, x: f64, y: f64, width: f64, height: f64, page: *Page) !void {
    try self.applyRect(x, y, width, height, .{
        .r = self._fill_style.r,
        .g = self._fill_style.g,
        .b = self._fill_style.b,
        .a = self._fill_style.a,
    }, page);
}
pub fn strokeRect(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64) void {}
pub fn beginPath(_: *CanvasRenderingContext2D) void {}
pub fn closePath(_: *CanvasRenderingContext2D) void {}
pub fn moveTo(_: *CanvasRenderingContext2D, _: f64, _: f64) void {}
pub fn lineTo(_: *CanvasRenderingContext2D, _: f64, _: f64) void {}
pub fn quadraticCurveTo(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64) void {}
pub fn bezierCurveTo(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64, _: f64, _: f64) void {}
pub fn arc(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64, _: f64, _: ?bool) void {}
pub fn arcTo(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64, _: f64) void {}
pub fn rect(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64) void {}
pub fn fill(_: *CanvasRenderingContext2D) void {}
pub fn stroke(_: *CanvasRenderingContext2D) void {}
pub fn clip(_: *CanvasRenderingContext2D) void {}
pub fn setFont(self: *CanvasRenderingContext2D, value: []const u8) void {
    // Parse CSS font shorthand: e.g. "12px Arial", "bold 14px serif", "italic 16px 'Times New Roman'"
    // We extract font-size (number followed by "px") and font-family (rest after size).
    var it = std.mem.tokenizeScalar(u8, value, ' ');
    var found_size: ?f64 = null;
    var family_start: usize = 0;
    var pos: usize = 0;
    while (it.next()) |token| {
        pos = @intFromPtr(token.ptr) - @intFromPtr(value.ptr) + token.len;
        if (std.mem.endsWith(u8, token, "px")) {
            found_size = std.fmt.parseFloat(f64, token[0 .. token.len - 2]) catch null;
            if (found_size != null) {
                family_start = pos;
            }
        }
    }
    if (found_size) |size| {
        if (size > 0) self._font_size = size;
        const family = std.mem.trim(u8, value[family_start..], " \t'\"");
        if (family.len > 0) self._font_family = family;
    }
}
pub fn setTextAlign(_: *CanvasRenderingContext2D, _: []const u8) void {}
pub fn setTextBaseline(_: *CanvasRenderingContext2D, _: []const u8) void {}

/// Character width factor relative to font-size for different font families.
/// These values are approximations of real browser character advance widths
/// and deliberately vary per font to produce different measureText results.
fn charWidthFactor(family: []const u8) f64 {
    const h = hashFontFamily(family);
    // Common fonts have distinct factors; unknown fonts get a hash-derived value
    if (std.ascii.eqlIgnoreCase(family, "monospace") or std.ascii.eqlIgnoreCase(family, "Courier New") or std.ascii.eqlIgnoreCase(family, "Courier")) {
        return 0.6;
    }
    if (std.ascii.eqlIgnoreCase(family, "serif") or std.ascii.eqlIgnoreCase(family, "Times New Roman") or std.ascii.eqlIgnoreCase(family, "Georgia")) {
        return 0.52;
    }
    if (std.ascii.eqlIgnoreCase(family, "sans-serif") or std.ascii.eqlIgnoreCase(family, "Arial") or std.ascii.eqlIgnoreCase(family, "Helvetica")) {
        return 0.55;
    }
    if (std.ascii.eqlIgnoreCase(family, "Verdana")) return 0.58;
    if (std.ascii.eqlIgnoreCase(family, "Impact")) return 0.42;
    if (std.ascii.eqlIgnoreCase(family, "Comic Sans MS")) return 0.54;
    if (std.ascii.eqlIgnoreCase(family, "Trebuchet MS")) return 0.53;
    // Hash-derived factor between 0.45 and 0.62 for unknown fonts
    return 0.45 + @as(f64, @floatFromInt(h % 170)) / 1000.0;
}

fn hashFontFamily(family: []const u8) u64 {
    var h: u64 = 5381;
    for (family) |c| {
        h = h *% 33 +% @as(u64, std.ascii.toLower(c));
    }
    return h;
}

const TextMetrics = struct {
    width: f64,
    actualBoundingBoxAscent: f64,
    actualBoundingBoxDescent: f64,
    actualBoundingBoxLeft: f64,
    actualBoundingBoxRight: f64,
    fontBoundingBoxAscent: f64,
    fontBoundingBoxDescent: f64,
    alphabeticBaseline: f64,
    hangingBaseline: f64,
    ideographicBaseline: f64,
    emHeightAscent: f64,
    emHeightDescent: f64,
};

pub fn measureText(self: *const CanvasRenderingContext2D, text: []const u8) TextMetrics {
    const font_size = self._font_size;
    const factor = charWidthFactor(self._font_family);
    const width = @as(f64, @floatFromInt(text.len)) * font_size * factor;
    const ascent = font_size * 0.8;
    const descent = font_size * 0.2;
    return .{
        .width = width,
        .actualBoundingBoxAscent = ascent,
        .actualBoundingBoxDescent = descent,
        .actualBoundingBoxLeft = 0.0,
        .actualBoundingBoxRight = width,
        .fontBoundingBoxAscent = font_size * 0.88,
        .fontBoundingBoxDescent = font_size * 0.24,
        .alphabeticBaseline = 0.0,
        .hangingBaseline = ascent * 0.8,
        .ideographicBaseline = -descent,
        .emHeightAscent = ascent,
        .emHeightDescent = descent,
    };
}

pub fn fillText(self: *CanvasRenderingContext2D, text: []const u8, x: f64, y: f64, _: ?f64, page: *Page) !void {
    // Deterministic text rendering: generate pixels based on text content, font, and position.
    // Uses a simple hash-based approach to create unique but stable pixel patterns per character.
    const font_size = self._font_size;
    const char_width = font_size * charWidthFactor(self._font_family);
    const char_height = font_size;
    const baseline_offset = font_size * 0.8; // approximate baseline

    const fill_color = Pixel{
        .r = self._fill_style.r,
        .g = self._fill_style.g,
        .b = self._fill_style.b,
        .a = self._fill_style.a,
    };

    for (text, 0..) |ch, ci| {
        const cx = x + @as(f64, @floatFromInt(ci)) * char_width;
        const cy = y - baseline_offset;

        // Generate a deterministic glyph pattern from the character value and font
        const glyph_seed = @as(u64, ch) *% 2654435761 +% hashFontFamily(self._font_family);
        const gw: usize = @intFromFloat(@max(1.0, @ceil(char_width)));
        const gh: usize = @intFromFloat(@max(1.0, @ceil(char_height)));

        for (0..gh) |gy| {
            for (0..gw) |gx| {
                // Deterministic pattern: use hash of position within glyph
                const pattern = (glyph_seed +% @as(u64, gx) *% 31 +% @as(u64, gy) *% 37) & 0xFF;
                // Only fill ~60% of pixels to simulate glyph shapes
                if (pattern < 153) {
                    const px_x = cx + @as(f64, @floatFromInt(gx));
                    const px_y = cy + @as(f64, @floatFromInt(gy));
                    if (px_x >= 0 and px_y >= 0 and px_x < 2048.0 and px_y < 2048.0) {
                        const key = packPixelKey(@intFromFloat(px_x), @intFromFloat(px_y));
                        // Modulate alpha slightly based on pattern for anti-aliasing appearance
                        const alpha_mod: u8 = @intCast(@min(@as(u64, 255), 128 + (pattern >> 1)));
                        const pixel = Pixel{
                            .r = fill_color.r,
                            .g = fill_color.g,
                            .b = fill_color.b,
                            .a = @min(fill_color.a, alpha_mod),
                        };
                        try self._pixels.put(page.arena, key, pixel);
                    }
                }
            }
        }
    }
}
pub fn strokeText(self: *CanvasRenderingContext2D, text: []const u8, x: f64, y: f64, max_width: ?f64, page: *Page) !void {
    // strokeText produces similar output to fillText for fingerprinting purposes
    try self.fillText(text, x, y, max_width, page);
}
pub fn drawImage(_: *CanvasRenderingContext2D, _: js.Value.Temp, _: []js.Value.Temp) void {}
pub fn getImageData(
    self: *CanvasRenderingContext2D,
    sx: js.Value,
    sy: js.Value,
    sw: js.Value,
    sh: js.Value,
    page: *Page,
) !ImageData {
    // Gracefully handle missing or non-numeric arguments by falling back to
    // a 1x1 transparent ImageData. Some fingerprinting scripts call getImageData
    // with non-standard arguments (e.g. a canvas element); returning an error
    // would expose "ERR" in the detection results.
    const sx_n = if (sy.isUndefined() or sw.isUndefined() or sh.isUndefined())
        0.0
    else
        sx.toF64() catch 0.0;
    const sy_n = if (sy.isUndefined()) 0.0 else sy.toF64() catch 0.0;
    const sw_n = if (sw.isUndefined()) 1.0 else (sw.toF64() catch 1.0);
    const sh_n = if (sh.isUndefined()) 1.0 else (sh.toF64() catch 1.0);

    if (!std.math.isFinite(sx_n) or !std.math.isFinite(sy_n) or !std.math.isFinite(sw_n) or !std.math.isFinite(sh_n)) {
        return error.IndexSizeError;
    }

    const max_side: f64 = 2048.0;
    const width_f = @min(max_side, @ceil(@abs(sw_n)));
    const height_f = @min(max_side, @ceil(@abs(sh_n)));
    if (width_f <= 0 or height_f <= 0) {
        return error.IndexSizeError;
    }

    const width: usize = @intFromFloat(width_f);
    const height: usize = @intFromFloat(height_f);
    const data = try page.call_arena.alloc(u8, width * height * 4);
    @memset(data, 0);

    const ox = @floor(@min(sx_n, sx_n + sw_n));
    const oy = @floor(@min(sy_n, sy_n + sh_n));
    for (0..height) |yy| {
        for (0..width) |xx| {
            const src_xf = ox + @as(f64, @floatFromInt(xx));
            const src_yf = oy + @as(f64, @floatFromInt(yy));
            if (src_xf < 0 or src_yf < 0 or src_xf > std.math.maxInt(u32) or src_yf > std.math.maxInt(u32)) {
                continue;
            }

            const src_x: u32 = @intFromFloat(src_xf);
            const src_y: u32 = @intFromFloat(src_yf);
            const key = packPixelKey(src_x, src_y);
            const pixel = self._pixels.get(key) orelse continue;
            const i = (yy * width + xx) * 4;
            data[i] = pixel.r;
            data[i + 1] = pixel.g;
            data[i + 2] = pixel.b;
            data[i + 3] = pixel.a;
        }
    }

    return .{
        .data = .{ .values = data },
        .width = @intCast(width),
        .height = @intCast(height),
    };
}
pub fn isPointInPath(_: *CanvasRenderingContext2D, _: f64, _: f64, _: ?[]const u8) bool {
    return false;
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(CanvasRenderingContext2D);

    pub const Meta = struct {
        pub const name = "CanvasRenderingContext2D";

        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const save = bridge.function(CanvasRenderingContext2D.save, .{});
    pub const restore = bridge.function(CanvasRenderingContext2D.restore, .{});

    pub const scale = bridge.function(CanvasRenderingContext2D.scale, .{});
    pub const rotate = bridge.function(CanvasRenderingContext2D.rotate, .{});
    pub const translate = bridge.function(CanvasRenderingContext2D.translate, .{});
    pub const transform = bridge.function(CanvasRenderingContext2D.transform, .{});
    pub const setTransform = bridge.function(CanvasRenderingContext2D.setTransform, .{});
    pub const resetTransform = bridge.function(CanvasRenderingContext2D.resetTransform, .{});

    pub const globalAlpha = bridge.accessor(CanvasRenderingContext2D.getGlobalAlpha, CanvasRenderingContext2D.setGlobalAlpha, .{});
    pub const globalCompositeOperation = bridge.accessor(CanvasRenderingContext2D.getGlobalCompositeOperation, CanvasRenderingContext2D.setGlobalCompositeOperation, .{});

    pub const fillStyle = bridge.accessor(CanvasRenderingContext2D.getFillStyle, CanvasRenderingContext2D.setFillStyle, .{});
    pub const strokeStyle = bridge.accessor(CanvasRenderingContext2D.getStrokeStyle, CanvasRenderingContext2D.setStrokeStyle, .{});

    pub const lineWidth = bridge.accessor(CanvasRenderingContext2D.getLineWidth, CanvasRenderingContext2D.setLineWidth, .{});
    pub const lineCap = bridge.accessor(CanvasRenderingContext2D.getLineCap, CanvasRenderingContext2D.setLineCap, .{});
    pub const lineJoin = bridge.accessor(CanvasRenderingContext2D.getLineJoin, CanvasRenderingContext2D.setLineJoin, .{});
    pub const miterLimit = bridge.accessor(CanvasRenderingContext2D.getMiterLimit, CanvasRenderingContext2D.setMiterLimit, .{});

    pub const clearRect = bridge.function(CanvasRenderingContext2D.clearRect, .{});
    pub const fillRect = bridge.function(CanvasRenderingContext2D.fillRect, .{});
    pub const strokeRect = bridge.function(CanvasRenderingContext2D.strokeRect, .{});

    pub const beginPath = bridge.function(CanvasRenderingContext2D.beginPath, .{});
    pub const closePath = bridge.function(CanvasRenderingContext2D.closePath, .{});
    pub const moveTo = bridge.function(CanvasRenderingContext2D.moveTo, .{});
    pub const lineTo = bridge.function(CanvasRenderingContext2D.lineTo, .{});
    pub const quadraticCurveTo = bridge.function(CanvasRenderingContext2D.quadraticCurveTo, .{});
    pub const bezierCurveTo = bridge.function(CanvasRenderingContext2D.bezierCurveTo, .{});
    pub const arc = bridge.function(CanvasRenderingContext2D.arc, .{});
    pub const arcTo = bridge.function(CanvasRenderingContext2D.arcTo, .{});
    pub const rect = bridge.function(CanvasRenderingContext2D.rect, .{});

    pub const fill = bridge.function(CanvasRenderingContext2D.fill, .{});
    pub const stroke = bridge.function(CanvasRenderingContext2D.stroke, .{});
    pub const clip = bridge.function(CanvasRenderingContext2D.clip, .{});

    pub const font = bridge.accessor(CanvasRenderingContext2D.getFont, CanvasRenderingContext2D.setFont, .{});
    pub const textAlign = bridge.accessor(CanvasRenderingContext2D.getTextAlign, CanvasRenderingContext2D.setTextAlign, .{});
    pub const textBaseline = bridge.accessor(CanvasRenderingContext2D.getTextBaseline, CanvasRenderingContext2D.setTextBaseline, .{});
    pub const fillText = bridge.function(CanvasRenderingContext2D.fillText, .{});
    pub const strokeText = bridge.function(CanvasRenderingContext2D.strokeText, .{});
    pub const measureText = bridge.function(CanvasRenderingContext2D.measureText, .{});
    pub const drawImage = bridge.function(CanvasRenderingContext2D.drawImage, .{});
    pub const getImageData = bridge.function(CanvasRenderingContext2D.getImageData, .{ .dom_exception = true });
    pub const isPointInPath = bridge.function(CanvasRenderingContext2D.isPointInPath, .{});
};

const testing = @import("../../../testing.zig");
test "WebApi: CanvasRenderingContext2D" {
    try testing.htmlRunner("canvas/canvas_rendering_context_2d.html", .{});
}
