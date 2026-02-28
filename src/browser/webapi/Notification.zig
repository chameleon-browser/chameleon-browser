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

const js = @import("../js/js.zig");
const Page = @import("../Page.zig");
const EventTarget = @import("EventTarget.zig");

const Notification = @This();

_proto: *EventTarget,
_title: []const u8,
_body: []const u8,
_icon: []const u8,
_tag: []const u8,

pub fn init(title: []const u8, options: ?Options, page: *Page) !*Notification {
    const opts = options orelse Options{};
    return page._factory.eventTarget(Notification{
        ._proto = undefined,
        ._title = try page.dupeString(title),
        ._body = if (opts.body) |b| try page.dupeString(b) else "",
        ._icon = if (opts.icon) |i| try page.dupeString(i) else "",
        ._tag = if (opts.tag) |t| try page.dupeString(t) else "",
    });
}

pub fn asEventTarget(self: *Notification) *EventTarget {
    return self._proto;
}

const Options = struct {
    body: ?[]const u8 = null,
    icon: ?[]const u8 = null,
    tag: ?[]const u8 = null,
};

pub fn getTitle(self: *const Notification) []const u8 {
    return self._title;
}

pub fn getBody(self: *const Notification) []const u8 {
    return self._body;
}

pub fn getIcon(self: *const Notification) []const u8 {
    return self._icon;
}

pub fn getTag(self: *const Notification) []const u8 {
    return self._tag;
}

pub fn close(_: *const Notification) void {}

// Static methods (no self parameter)
pub fn getPermission() []const u8 {
    return "default";
}

pub fn requestPermission(page: *Page) !js.Promise {
    return page.js.local.?.resolvePromise("denied");
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(Notification);

    pub const Meta = struct {
        pub const name = "Notification";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const constructor = bridge.constructor(Notification.init, .{});

    // Instance properties (readonly)
    pub const title = bridge.accessor(Notification.getTitle, null, .{});
    pub const body = bridge.accessor(Notification.getBody, null, .{});
    pub const icon = bridge.accessor(Notification.getIcon, null, .{});
    pub const tag = bridge.accessor(Notification.getTag, null, .{});

    // Instance method
    pub const close = bridge.function(Notification.close, .{});

    // Static property
    pub const permission = bridge.accessor(Notification.getPermission, null, .{ .static = true });

    // Static method
    pub const requestPermission = bridge.function(Notification.requestPermission, .{ .static = true });
};
