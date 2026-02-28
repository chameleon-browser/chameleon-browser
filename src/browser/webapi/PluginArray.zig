// Copyright (C) 2023-2026  Lightpanda (Selecy SAS)
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
const js = @import("../js/js.zig");

pub fn registerTypes() []const type {
    return &.{ PluginArray, MimeTypeArray, Plugin, MimeType };
}

const PluginArray = @This();

const num_plugins = 5;
const num_mimes = 2;

_pad: bool = false,

pub fn refresh(_: *const PluginArray) void {}

pub fn getAtIndex(_: *const PluginArray, index: usize) ?*Plugin {
    if (index >= num_plugins) return null;
    return &plugins[index];
}

pub fn getByName(_: *const PluginArray, name: []const u8) ?*Plugin {
    for (0..num_plugins) |i| {
        if (std.mem.eql(u8, plugins[i]._name, name)) {
            return &plugins[i];
        }
    }
    return null;
}

pub const Plugin = struct {
    _name: []const u8,
    _description: []const u8,
    _filename: []const u8,

    pub fn getName(self: *const Plugin) []const u8 {
        return self._name;
    }

    pub fn getDescription(self: *const Plugin) []const u8 {
        return self._description;
    }

    pub fn getFilename(self: *const Plugin) []const u8 {
        return self._filename;
    }

    pub fn getAtIndex(_: *const Plugin, index: usize) ?*MimeType {
        if (index >= num_mimes) return null;
        return &mime_types[index];
    }

    pub fn getByName(_: *const Plugin, name: []const u8) ?*MimeType {
        for (0..num_mimes) |i| {
            if (std.mem.eql(u8, mime_types[i]._type, name)) {
                return &mime_types[i];
            }
        }
        return null;
    }

    pub const JsApi = struct {
        pub const bridge = js.Bridge(Plugin);
        pub const Meta = struct {
            pub const name = "Plugin";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const name = bridge.accessor(Plugin.getName, null, .{});
        pub const description = bridge.accessor(Plugin.getDescription, null, .{});
        pub const filename = bridge.accessor(Plugin.getFilename, null, .{});
        pub const length = bridge.property(num_mimes, .{ .template = false });
        pub const @"[int]" = bridge.indexed(Plugin.getAtIndex, .{ .null_as_undefined = true });
        pub const @"[str]" = bridge.namedIndexed(Plugin.getByName, null, null, .{ .null_as_undefined = true });
        pub const item = bridge.function(_item, .{});
        fn _item(_: *const Plugin, index: i32) ?*MimeType {
            if (index < 0 or index >= num_mimes) return null;
            return &mime_types[@intCast(index)];
        }
        pub const namedItem = bridge.function(Plugin.getByName, .{});
    };
};

pub const MimeTypeArray = struct {
    _pad: bool = false,

    pub fn getAtIndex(_: *const MimeTypeArray, index: usize) ?*MimeType {
        if (index >= num_mimes) return null;
        return &mime_types[index];
    }

    pub fn getByType(_: *const MimeTypeArray, mime_type: []const u8) ?*MimeType {
        for (0..num_mimes) |i| {
            if (std.mem.eql(u8, mime_types[i]._type, mime_type)) {
                return &mime_types[i];
            }
        }
        return null;
    }

    pub const JsApi = struct {
        pub const bridge = js.Bridge(MimeTypeArray);
        pub const Meta = struct {
            pub const name = "MimeTypeArray";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
            pub const empty_with_no_proto = true;
        };

        pub const length = bridge.property(num_mimes, .{ .template = false });
        pub const @"[int]" = bridge.indexed(MimeTypeArray.getAtIndex, .{ .null_as_undefined = true });
        pub const @"[str]" = bridge.namedIndexed(MimeTypeArray.getByType, null, null, .{ .null_as_undefined = true });
        pub const item = bridge.function(_item, .{});
        fn _item(self: *const MimeTypeArray, index: i32) ?*MimeType {
            if (index < 0) {
                return null;
            }
            return self.getAtIndex(@intCast(index));
        }
        pub const namedItem = bridge.function(MimeTypeArray.getByType, .{});
    };
};

pub const MimeType = struct {
    _type: []const u8 = "application/pdf",
    _description: []const u8 = "Portable Document Format",
    _suffixes: []const u8 = "pdf",

    pub fn getType(self: *const MimeType) []const u8 {
        return self._type;
    }

    pub fn getDescription(self: *const MimeType) []const u8 {
        return self._description;
    }

    pub fn getSuffixes(self: *const MimeType) []const u8 {
        return self._suffixes;
    }

    pub fn getEnabledPlugin(_: *const MimeType) *Plugin {
        return &plugins[0];
    }

    pub const JsApi = struct {
        pub const bridge = js.Bridge(MimeType);
        pub const Meta = struct {
            pub const name = "MimeType";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const @"type" = bridge.accessor(MimeType.getType, null, .{});
        pub const description = bridge.accessor(MimeType.getDescription, null, .{});
        pub const suffixes = bridge.accessor(MimeType.getSuffixes, null, .{});
        pub const enabledPlugin = bridge.accessor(MimeType.getEnabledPlugin, null, .{});
    };
};

var plugins = [num_plugins]Plugin{
    .{ ._name = "PDF Viewer", ._description = "Portable Document Format", ._filename = "internal-pdf-viewer" },
    .{ ._name = "Chrome PDF Viewer", ._description = "Portable Document Format", ._filename = "internal-pdf-viewer" },
    .{ ._name = "Chromium PDF Viewer", ._description = "Portable Document Format", ._filename = "internal-pdf-viewer" },
    .{ ._name = "Microsoft Edge PDF Viewer", ._description = "Portable Document Format", ._filename = "internal-pdf-viewer" },
    .{ ._name = "WebKit built-in PDF", ._description = "Portable Document Format", ._filename = "internal-pdf-viewer" },
};

var mime_types = [num_mimes]MimeType{
    .{ ._type = "application/pdf", ._description = "Portable Document Format", ._suffixes = "pdf" },
    .{ ._type = "text/pdf", ._description = "Portable Document Format", ._suffixes = "pdf" },
};

pub const JsApi = struct {
    pub const bridge = js.Bridge(PluginArray);

    pub const Meta = struct {
        pub const name = "PluginArray";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
        pub const empty_with_no_proto = true;
    };

    pub const length = bridge.property(5, .{ .template = false });
    pub const refresh = bridge.function(PluginArray.refresh, .{});
    pub const @"[int]" = bridge.indexed(PluginArray.getAtIndex, .{ .null_as_undefined = true });
    pub const @"[str]" = bridge.namedIndexed(PluginArray.getByName, null, null, .{ .null_as_undefined = true });
    pub const item = bridge.function(_item, .{});
    fn _item(self: *const PluginArray, index: i32) ?*Plugin {
        if (index < 0) {
            return null;
        }
        return self.getAtIndex(@intCast(index));
    }
    pub const namedItem = bridge.function(PluginArray.getByName, .{});
};
