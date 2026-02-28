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

// zlint-disable unused-decls
const std = @import("std");
const js = @import("../../js/js.zig");
const EventTarget = @import("../EventTarget.zig");

const MediaQueryList = @This();

_proto: *EventTarget,
_media: []const u8,

pub fn deinit(self: *MediaQueryList) void {
    _ = self;
}

pub fn asEventTarget(self: *MediaQueryList) *EventTarget {
    return self._proto;
}

pub fn getMedia(self: *const MediaQueryList) []const u8 {
    return self._media;
}

/// Evaluates common media queries using simple string matching.
/// Assumes a standard desktop viewport of 1920x1080 with light color scheme.
pub fn getMatches(self: *const MediaQueryList) bool {
    return evaluateMediaQuery(self._media);
}

const assumed_width: u32 = 1920;

fn evaluateMediaQuery(query: []const u8) bool {
    const trimmed = std.mem.trim(u8, query, " \t\r\n");
    if (trimmed.len == 0) return false;

    // Handle "not <query>" - negate the inner result
    if (std.mem.startsWith(u8, trimmed, "not ")) {
        return !evaluateMediaQuery(trimmed[4..]);
    }

    // Handle "only <query>" - same as evaluating the inner query
    if (std.mem.startsWith(u8, trimmed, "only ")) {
        return evaluateMediaQuery(trimmed[5..]);
    }

    // Handle comma-separated queries (OR logic): any match -> true
    if (std.mem.indexOfScalar(u8, trimmed, ',')) |_| {
        var it = std.mem.splitScalar(u8, trimmed, ',');
        while (it.next()) |part| {
            if (evaluateMediaQuery(part)) return true;
        }
        return false;
    }

    // Handle "type and (feature)" combinations
    if (std.mem.indexOf(u8, trimmed, " and ")) |idx| {
        const left = std.mem.trim(u8, trimmed[0..idx], " \t\r\n");
        const right = std.mem.trim(u8, trimmed[idx + 5 ..], " \t\r\n");
        return evaluateMediaQuery(left) and evaluateMediaQuery(right);
    }

    // Media types
    if (std.mem.eql(u8, trimmed, "all")) return true;
    if (std.mem.eql(u8, trimmed, "screen")) return true;
    if (std.mem.eql(u8, trimmed, "print")) return false;
    if (std.mem.eql(u8, trimmed, "tty")) return false;
    if (std.mem.eql(u8, trimmed, "tv")) return false;
    if (std.mem.eql(u8, trimmed, "projection")) return false;
    if (std.mem.eql(u8, trimmed, "handheld")) return false;
    if (std.mem.eql(u8, trimmed, "braille")) return false;
    if (std.mem.eql(u8, trimmed, "embossed")) return false;
    if (std.mem.eql(u8, trimmed, "aural")) return false;
    if (std.mem.eql(u8, trimmed, "speech")) return false;

    // Strip outer parentheses for feature queries
    if (std.mem.startsWith(u8, trimmed, "(") and std.mem.endsWith(u8, trimmed, ")")) {
        const inner = std.mem.trim(u8, trimmed[1 .. trimmed.len - 1], " \t\r\n");
        return evaluateFeature(inner);
    }

    // Unrecognized
    return false;
}

fn parsePxValue(val: []const u8) ?u32 {
    const s = std.mem.trim(u8, val, " \t\r\n");
    if (std.mem.endsWith(u8, s, "px")) {
        return std.fmt.parseInt(u32, s[0 .. s.len - 2], 10) catch null;
    }
    return null;
}

fn evaluateFeature(feature: []const u8) bool {
    // Boolean features (no colon)
    if (std.mem.indexOfScalar(u8, feature, ':') == null) {
        if (std.mem.eql(u8, feature, "color")) return true;
        if (std.mem.eql(u8, feature, "grid")) return false;
        return false;
    }

    // key: value features
    if (std.mem.indexOfScalar(u8, feature, ':')) |colon| {
        const key = std.mem.trim(u8, feature[0..colon], " \t\r\n");
        const val = std.mem.trim(u8, feature[colon + 1 ..], " \t\r\n");

        // Width features
        if (std.mem.eql(u8, key, "min-width")) {
            if (parsePxValue(val)) |px| return assumed_width >= px;
            return false;
        }
        if (std.mem.eql(u8, key, "max-width")) {
            if (parsePxValue(val)) |px| return assumed_width <= px;
            return false;
        }
        if (std.mem.eql(u8, key, "width")) {
            if (parsePxValue(val)) |px| return assumed_width == px;
            return false;
        }

        // Color scheme
        if (std.mem.eql(u8, key, "prefers-color-scheme")) {
            return std.mem.eql(u8, val, "light");
        }

        // Motion preference
        if (std.mem.eql(u8, key, "prefers-reduced-motion")) {
            return std.mem.eql(u8, val, "no-preference");
        }

        // Contrast preference
        if (std.mem.eql(u8, key, "prefers-contrast")) {
            return std.mem.eql(u8, val, "no-preference");
        }

        // Hover capability
        if (std.mem.eql(u8, key, "hover")) {
            return std.mem.eql(u8, val, "hover");
        }
        if (std.mem.eql(u8, key, "any-hover")) {
            return std.mem.eql(u8, val, "hover");
        }

        // Pointer capability
        if (std.mem.eql(u8, key, "pointer")) {
            return std.mem.eql(u8, val, "fine");
        }
        if (std.mem.eql(u8, key, "any-pointer")) {
            return std.mem.eql(u8, val, "fine");
        }

        // Color depth
        if (std.mem.eql(u8, key, "min-color")) {
            if (std.fmt.parseInt(u32, val, 10)) |bits| {
                return bits <= 8;
            } else |_| {
                return false;
            }
        }
        if (std.mem.eql(u8, key, "color-gamut")) {
            return std.mem.eql(u8, val, "srgb");
        }

        // Display mode
        if (std.mem.eql(u8, key, "display-mode")) {
            return std.mem.eql(u8, val, "browser");
        }

        // Orientation (1920x1080 = landscape)
        if (std.mem.eql(u8, key, "orientation")) {
            return std.mem.eql(u8, val, "landscape");
        }

        // Scripting support
        if (std.mem.eql(u8, key, "scripting")) {
            return std.mem.eql(u8, val, "enabled");
        }
    }

    // Unrecognized feature
    return false;
}

pub fn addListener(_: *const MediaQueryList, _: js.Function) void {}
pub fn removeListener(_: *const MediaQueryList, _: js.Function) void {}

pub const JsApi = struct {
    pub const bridge = js.Bridge(MediaQueryList);

    pub const Meta = struct {
        pub const name = "MediaQueryList";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const media = bridge.accessor(MediaQueryList.getMedia, null, .{});
    pub const matches = bridge.accessor(MediaQueryList.getMatches, null, .{});
    pub const addListener = bridge.function(MediaQueryList.addListener, .{});
    pub const removeListener = bridge.function(MediaQueryList.removeListener, .{});
};

const testing = @import("../../../testing.zig");
test "WebApi: MediaQueryList" {
    try testing.htmlRunner("css/media_query_list.html", .{});
}
