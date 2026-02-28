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
const Page = @import("../Page.zig");

const WebSocket = @This();

_url: []const u8,

pub fn init(url: []const u8, page: *Page) !*WebSocket {
    if (!std.mem.startsWith(u8, url, "ws://") and !std.mem.startsWith(u8, url, "wss://")) {
        return error.WebSocketInvalidURL;
    }
    return page._factory.create(WebSocket{ ._url = try page.dupeString(url) });
}

pub fn getUrl(self: *const WebSocket) []const u8 {
    return self._url;
}

pub fn close(_: *const WebSocket) void {}

pub const JsApi = struct {
    pub const bridge = js.Bridge(WebSocket);

    pub const Meta = struct {
        pub const name = "WebSocket";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const constructor = bridge.constructor(WebSocket.init, .{ .dom_exception = true });
    pub const url = bridge.accessor(WebSocket.getUrl, null, .{});
    pub const close = bridge.function(WebSocket.close, .{});

    pub const CONNECTING = bridge.property(0, .{ .template = false });
    pub const OPEN = bridge.property(1, .{ .template = false });
    pub const CLOSING = bridge.property(2, .{ .template = false });
    pub const CLOSED = bridge.property(3, .{ .template = false });
};
