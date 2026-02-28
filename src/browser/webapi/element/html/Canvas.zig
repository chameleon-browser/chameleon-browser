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
const js = @import("../../../js/js.zig");
const Page = @import("../../../Page.zig");
const Node = @import("../../Node.zig");
const Element = @import("../../Element.zig");
const HtmlElement = @import("../Html.zig");
const png = @import("../../canvas/png.zig");

const CanvasRenderingContext2D = @import("../../canvas/CanvasRenderingContext2D.zig");
const WebGLRenderingContext = @import("../../canvas/WebGLRenderingContext.zig");

const Canvas = @This();
_proto: *HtmlElement,
_context_2d: ?*CanvasRenderingContext2D = null,
_context_webgl: ?*WebGLRenderingContext = null,

pub fn asElement(self: *Canvas) *Element {
    return self._proto._proto;
}
pub fn asConstElement(self: *const Canvas) *const Element {
    return self._proto._proto;
}
pub fn asNode(self: *Canvas) *Node {
    return self.asElement().asNode();
}

pub fn getWidth(self: *const Canvas) u32 {
    const attr = self.asConstElement().getAttributeSafe(comptime .wrap("width")) orelse return 300;
    return std.fmt.parseUnsigned(u32, attr, 10) catch 300;
}

pub fn setWidth(self: *Canvas, value: u32, page: *Page) !void {
    const str = try std.fmt.allocPrint(page.call_arena, "{d}", .{value});
    try self.asElement().setAttributeSafe(comptime .wrap("width"), .wrap(str), page);
}

pub fn getHeight(self: *const Canvas) u32 {
    const attr = self.asConstElement().getAttributeSafe(comptime .wrap("height")) orelse return 150;
    return std.fmt.parseUnsigned(u32, attr, 10) catch 150;
}

pub fn setHeight(self: *Canvas, value: u32, page: *Page) !void {
    const str = try std.fmt.allocPrint(page.call_arena, "{d}", .{value});
    try self.asElement().setAttributeSafe(comptime .wrap("height"), .wrap(str), page);
}

/// Since there's no base class rendering contextes inherit from,
/// we're using tagged union.
const DrawingContext = union(enum) {
    @"2d": *CanvasRenderingContext2D,
    webgl: *WebGLRenderingContext,
};

pub fn getContext(self: *Canvas, context_type: []const u8, page: *Page) !?DrawingContext {
    if (std.mem.eql(u8, context_type, "2d")) {
        if (self._context_2d) |ctx| {
            return .{ .@"2d" = ctx };
        }
        const ctx = try page._factory.create(CanvasRenderingContext2D{});
        self._context_2d = ctx;
        return .{ .@"2d" = ctx };
    }

    if (std.mem.eql(u8, context_type, "webgl") or std.mem.eql(u8, context_type, "experimental-webgl")) {
        if (self._context_webgl) |ctx| {
            return .{ .webgl = ctx };
        }
        const ctx = try page._factory.create(WebGLRenderingContext{});
        self._context_webgl = ctx;
        return .{ .webgl = ctx };
    }

    return null;
}

pub fn toDataURL(self: *const Canvas, page: *Page) ![]const u8 {
    const width = self.getWidth();
    const height = self.getHeight();

    // Generate raw RGBA pixel data
    const pixel_count = @as(usize, width) * @as(usize, height);
    const rgba_data = try page.call_arena.alloc(u8, pixel_count * 4);
    @memset(rgba_data, 0);

    if (self._context_2d) |context| {
        for (0..height) |y| {
            for (0..width) |x| {
                const key = CanvasRenderingContext2D.packPixelKey(@intCast(x), @intCast(y));
                if (context._pixels.get(key)) |pixel| {
                    const i = (y * width + x) * 4;
                    rgba_data[i] = pixel.r;
                    rgba_data[i + 1] = pixel.g;
                    rgba_data[i + 2] = pixel.b;
                    rgba_data[i + 3] = pixel.a;
                }
            }
        }
    } else if (self._context_webgl != null) {
        // WebGL context: generate a deterministic non-blank image
        // (simulates rendered WebGL content for fingerprinting purposes)
        for (0..height) |y| {
            for (0..width) |x| {
                const i = (y * width + x) * 4;
                // Deterministic gradient pattern unique to canvas size
                const seed: u32 = @as(u32, @intCast(x)) *% 2654435761 +% @as(u32, @intCast(y)) *% 340573321;
                rgba_data[i] = @intCast((seed >> 0) & 0xFF); // R
                rgba_data[i + 1] = @intCast((seed >> 8) & 0xFF); // G
                rgba_data[i + 2] = @intCast((seed >> 16) & 0xFF); // B
                rgba_data[i + 3] = 255; // A: fully opaque
            }
        }
    }

    // Encode as PNG and return data URL
    return png.encodeDataURL(page.call_arena, rgba_data, width, height);
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(Canvas);

    pub const Meta = struct {
        pub const name = "HTMLCanvasElement";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const width = bridge.accessor(Canvas.getWidth, Canvas.setWidth, .{});
    pub const height = bridge.accessor(Canvas.getHeight, Canvas.setHeight, .{});
    pub const getContext = bridge.function(Canvas.getContext, .{});
    pub const toDataURL = bridge.function(Canvas.toDataURL, .{});
};
