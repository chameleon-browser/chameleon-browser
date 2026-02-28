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
const Page = @import("../../Page.zig");

pub fn registerTypes() []const type {
    return &.{
        WebGLRenderingContext,
        // Extension types should be runtime generated. We might want
        // to revisit this.
        Extension.Type.WEBGL_debug_renderer_info,
        Extension.Type.WEBGL_lose_context,
    };
}

const WebGLRenderingContext = @This();

/// On Chrome and Safari, a call to `getSupportedExtensions` returns total of 39.
/// The reference for it lists lesser number of extensions:
/// https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/Using_Extensions#extension_list
pub const Extension = union(enum) {
    ANGLE_instanced_arrays: void,
    EXT_blend_minmax: void,
    EXT_clip_control: void,
    EXT_color_buffer_half_float: void,
    EXT_depth_clamp: void,
    EXT_disjoint_timer_query: void,
    EXT_float_blend: void,
    EXT_frag_depth: void,
    EXT_polygon_offset_clamp: void,
    EXT_shader_texture_lod: void,
    EXT_texture_compression_bptc: void,
    EXT_texture_compression_rgtc: void,
    EXT_texture_filter_anisotropic: void,
    EXT_texture_mirror_clamp_to_edge: void,
    EXT_sRGB: void,
    KHR_parallel_shader_compile: void,
    OES_element_index_uint: void,
    OES_fbo_render_mipmap: void,
    OES_standard_derivatives: void,
    OES_texture_float: void,
    OES_texture_float_linear: void,
    OES_texture_half_float: void,
    OES_texture_half_float_linear: void,
    OES_vertex_array_object: void,
    WEBGL_blend_func_extended: void,
    WEBGL_color_buffer_float: void,
    WEBGL_compressed_texture_astc: void,
    WEBGL_compressed_texture_etc: void,
    WEBGL_compressed_texture_etc1: void,
    WEBGL_compressed_texture_pvrtc: void,
    WEBGL_compressed_texture_s3tc: void,
    WEBGL_compressed_texture_s3tc_srgb: void,
    WEBGL_debug_renderer_info: *Type.WEBGL_debug_renderer_info,
    WEBGL_debug_shaders: void,
    WEBGL_depth_texture: void,
    WEBGL_draw_buffers: void,
    WEBGL_lose_context: *Type.WEBGL_lose_context,
    WEBGL_multi_draw: void,
    WEBGL_polygon_mode: void,

    /// Reified enum type from the fields of this union.
    const Kind = blk: {
        const info = @typeInfo(Extension).@"union";
        const fields = info.fields;
        var items: [fields.len]std.builtin.Type.EnumField = undefined;
        for (fields, 0..) |field, i| {
            items[i] = .{ .name = field.name, .value = i };
        }

        break :blk @Type(.{
            .@"enum" = .{
                .tag_type = std.math.IntFittingRange(0, if (fields.len == 0) 0 else fields.len - 1),
                .fields = &items,
                .decls = &.{},
                .is_exhaustive = true,
            },
        });
    };

    /// Returns the `Extension.Kind` by its name.
    fn find(name: []const u8) ?Kind {
        // Just to make you really sad, this function has to be case-insensitive.
        // So here we copy what's being done in `std.meta.stringToEnum` but replace
        // the comparison function.
        const kvs = comptime build_kvs: {
            const T = Extension.Kind;
            const EnumKV = struct { []const u8, T };
            var kvs_array: [@typeInfo(T).@"enum".fields.len]EnumKV = undefined;
            for (@typeInfo(T).@"enum".fields, 0..) |enumField, i| {
                kvs_array[i] = .{ enumField.name, @field(T, enumField.name) };
            }
            break :build_kvs kvs_array[0..];
        };
        const Map = std.StaticStringMapWithEql(Extension.Kind, std.static_string_map.eqlAsciiIgnoreCase);
        const map = Map.initComptime(kvs);
        return map.get(name);
    }

    /// Extension types.
    pub const Type = struct {
        pub const WEBGL_debug_renderer_info = struct {
            _: u8 = 0,
            pub const UNMASKED_VENDOR_WEBGL: u64 = 0x9245;
            pub const UNMASKED_RENDERER_WEBGL: u64 = 0x9246;

            pub fn getUnmaskedVendorWebGL(_: *const WEBGL_debug_renderer_info) u64 {
                return UNMASKED_VENDOR_WEBGL;
            }

            pub fn getUnmaskedRendererWebGL(_: *const WEBGL_debug_renderer_info) u64 {
                return UNMASKED_RENDERER_WEBGL;
            }

            pub const JsApi = struct {
                pub const bridge = js.Bridge(WEBGL_debug_renderer_info);

                pub const Meta = struct {
                    pub const name = "WEBGL_debug_renderer_info";

                    pub const prototype_chain = bridge.prototypeChain();
                    pub var class_id: bridge.ClassId = undefined;
                };

                pub const UNMASKED_VENDOR_WEBGL = bridge.accessor(WEBGL_debug_renderer_info.getUnmaskedVendorWebGL, null, .{});
                pub const UNMASKED_RENDERER_WEBGL = bridge.accessor(WEBGL_debug_renderer_info.getUnmaskedRendererWebGL, null, .{});
            };
        };

        pub const WEBGL_lose_context = struct {
            _: u8 = 0,
            pub fn loseContext(_: *const WEBGL_lose_context) void {}
            pub fn restoreContext(_: *const WEBGL_lose_context) void {}

            pub const JsApi = struct {
                pub const bridge = js.Bridge(WEBGL_lose_context);

                pub const Meta = struct {
                    pub const name = "WEBGL_lose_context";

                    pub const prototype_chain = bridge.prototypeChain();
                    pub var class_id: bridge.ClassId = undefined;
                };

                pub const loseContext = bridge.function(WEBGL_lose_context.loseContext, .{});
                pub const restoreContext = bridge.function(WEBGL_lose_context.restoreContext, .{});
            };
        };
    };
};

/// WebGL parameter constants
const GL_VENDOR: u32 = 0x1F00;
const GL_RENDERER: u32 = 0x1F01;
const GL_VERSION: u32 = 0x1F02;
const GL_SHADING_LANGUAGE_VERSION: u32 = 0x8B8C;
const GL_UNMASKED_VENDOR_WEBGL: u32 = 0x9245;
const GL_UNMASKED_RENDERER_WEBGL: u32 = 0x9246;

/// Returns the value of the specified WebGL parameter.
/// GPU vendor/renderer are read from the session's randomly-selected GPU profile,
/// ensuring they stay consistent within a browser instance.
pub fn getParameter(_: *const WebGLRenderingContext, pname: u32, page: *Page) []const u8 {
    return switch (pname) {
        GL_VENDOR => "WebKit",
        GL_RENDERER => "WebKit WebGL",
        GL_VERSION => "WebGL 1.0 (OpenGL ES 2.0 Chromium)",
        GL_SHADING_LANGUAGE_VERSION => "WebGL GLSL ES 1.0 (OpenGL ES GLSL ES 1.0 Chromium)",
        GL_UNMASKED_VENDOR_WEBGL => page._session.gpuVendor(),
        GL_UNMASKED_RENDERER_WEBGL => page._session.gpuRenderer(),
        else => "",
    };
}

/// Enables a WebGL extension.
pub fn getExtension(_: *const WebGLRenderingContext, name: []const u8, page: *Page) !?Extension {
    const tag = Extension.find(name) orelse return null;

    return switch (tag) {
        .WEBGL_debug_renderer_info => {
            const info = try page._factory.create(Extension.Type.WEBGL_debug_renderer_info{});
            return .{ .WEBGL_debug_renderer_info = info };
        },
        .WEBGL_lose_context => {
            const ctx = try page._factory.create(Extension.Type.WEBGL_lose_context{});
            return .{ .WEBGL_lose_context = ctx };
        },
        inline else => |comptime_enum| @unionInit(Extension, @tagName(comptime_enum), {}),
    };
}

/// Returns a list of all the supported WebGL extensions.
pub fn getSupportedExtensions(_: *const WebGLRenderingContext) []const []const u8 {
    return std.meta.fieldNames(Extension.Kind);
}

// ---------------------------------------------------------------------------
// Stub WebGL drawing methods — enough for fingerprint scripts to run without
// crashing. No actual rendering occurs; toDataURL returns a deterministic PNG.
// ---------------------------------------------------------------------------
pub fn createShader(_: *WebGLRenderingContext, _: u32) u32 {
    return 1;
}
pub fn shaderSource(_: *WebGLRenderingContext, _: u32, _: []const u8) void {}
pub fn compileShader(_: *WebGLRenderingContext, _: u32) void {}
pub fn createProgram(_: *WebGLRenderingContext) u32 {
    return 1;
}
pub fn attachShader(_: *WebGLRenderingContext, _: u32, _: u32) void {}
pub fn linkProgram(_: *WebGLRenderingContext, _: u32) void {}
pub fn useProgram(_: *WebGLRenderingContext, _: u32) void {}
pub fn createBuffer(_: *WebGLRenderingContext) u32 {
    return 1;
}
pub fn bindBuffer(_: *WebGLRenderingContext, _: u32, _: u32) void {}
pub fn enableVertexAttribArray(_: *WebGLRenderingContext, _: u32) void {}
pub fn vertexAttribPointer(_: *WebGLRenderingContext, _: u32, _: u32, _: u32, _: bool, _: u32, _: u32) void {}
pub fn getAttribLocation(_: *WebGLRenderingContext, _: u32, _: []const u8) i32 {
    return 0;
}
pub fn clearColor(_: *WebGLRenderingContext, _: f64, _: f64, _: f64, _: f64) void {}
pub fn clear(_: *WebGLRenderingContext, _: u32) void {}
pub fn drawArrays(_: *WebGLRenderingContext, _: u32, _: u32, _: u32) void {}
// NOTE: "bufferData" cannot be exposed as a bridge function — the exact name causes
// a mysterious V8 runtime failure where Castle.js crashes (TypeError in minified code).
// All other names (bufferDat, bufferDataa, xbufferData, etc.) work fine.
// The WebGL fingerprint image falls back to "undefined" without this.

pub const JsApi = struct {
    pub const bridge = js.Bridge(WebGLRenderingContext);

    pub const Meta = struct {
        pub const name = "WebGLRenderingContext";

        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const getParameter = bridge.function(WebGLRenderingContext.getParameter, .{});
    pub const getExtension = bridge.function(WebGLRenderingContext.getExtension, .{});
    pub const getSupportedExtensions = bridge.function(WebGLRenderingContext.getSupportedExtensions, .{});
    pub const createShader = bridge.function(WebGLRenderingContext.createShader, .{});
    pub const shaderSource = bridge.function(WebGLRenderingContext.shaderSource, .{});
    pub const compileShader = bridge.function(WebGLRenderingContext.compileShader, .{});
    pub const createProgram = bridge.function(WebGLRenderingContext.createProgram, .{});
    pub const attachShader = bridge.function(WebGLRenderingContext.attachShader, .{});
    pub const linkProgram = bridge.function(WebGLRenderingContext.linkProgram, .{});
    pub const useProgram = bridge.function(WebGLRenderingContext.useProgram, .{});
    pub const createBuffer = bridge.function(WebGLRenderingContext.createBuffer, .{});
    pub const bindBuffer = bridge.function(WebGLRenderingContext.bindBuffer, .{});
    pub const enableVertexAttribArray = bridge.function(WebGLRenderingContext.enableVertexAttribArray, .{});
    pub const vertexAttribPointer = bridge.function(WebGLRenderingContext.vertexAttribPointer, .{});
    pub const getAttribLocation = bridge.function(WebGLRenderingContext.getAttribLocation, .{});
    pub const clearColor = bridge.function(WebGLRenderingContext.clearColor, .{});
    pub const clear = bridge.function(WebGLRenderingContext.clear, .{});
    pub const drawArrays = bridge.function(WebGLRenderingContext.drawArrays, .{});

    // WebGL constants
    pub const VERTEX_SHADER = bridge.property(@as(u32, 0x8B31), .{ .template = false });
    pub const FRAGMENT_SHADER = bridge.property(@as(u32, 0x8B30), .{ .template = false });
    pub const ARRAY_BUFFER = bridge.property(@as(u32, 0x8892), .{ .template = false });
    pub const STATIC_DRAW = bridge.property(@as(u32, 0x88E4), .{ .template = false });
    pub const FLOAT = bridge.property(@as(u32, 0x1406), .{ .template = false });
    pub const COLOR_BUFFER_BIT = bridge.property(@as(u32, 0x4000), .{ .template = false });
    pub const TRIANGLES = bridge.property(@as(u32, 0x0004), .{ .template = false });
    pub const LINES = bridge.property(@as(u32, 0x0001), .{ .template = false });
    pub const DEPTH_BUFFER_BIT = bridge.property(@as(u32, 0x0100), .{ .template = false });
    pub const BLEND = bridge.property(@as(u32, 0x0BE2), .{ .template = false });
    pub const SRC_ALPHA = bridge.property(@as(u32, 0x0302), .{ .template = false });
    pub const ONE_MINUS_SRC_ALPHA = bridge.property(@as(u32, 0x0303), .{ .template = false });
    pub const DEPTH_TEST = bridge.property(@as(u32, 0x0B71), .{ .template = false });
    pub const LINE_STRIP = bridge.property(@as(u32, 0x0003), .{ .template = false });
    pub const TRIANGLE_STRIP = bridge.property(@as(u32, 0x0005), .{ .template = false });
    pub const TRIANGLE_FAN = bridge.property(@as(u32, 0x0006), .{ .template = false });
    pub const POINTS = bridge.property(@as(u32, 0x0000), .{ .template = false });
};

const testing = @import("../../../testing.zig");
test "WebApi: WebGLRenderingContext" {
    try testing.htmlRunner("canvas/webgl_rendering_context.html", .{});
}
