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

const MediaDevices = @This();

_pad: bool = false,

pub const init: MediaDevices = .{};

const MediaDeviceInfo = struct {
    deviceId: []const u8,
    kind: []const u8,
    label: []const u8,
    groupId: []const u8,
};

// A realistic default set: one audio output (speakers) which is always
// reported even without getUserMedia permission, plus one audioinput
// and one videoinput (labels hidden without permission).
const default_devices: [3]MediaDeviceInfo = .{
    .{
        .deviceId = "default",
        .kind = "audiooutput",
        .label = "",
        .groupId = "default",
    },
    .{
        .deviceId = "",
        .kind = "audioinput",
        .label = "",
        .groupId = "",
    },
    .{
        .deviceId = "",
        .kind = "videoinput",
        .label = "",
        .groupId = "",
    },
};

pub fn enumerateDevices(_: *const MediaDevices, page: *Page) !js.Promise {
    const devices: []const MediaDeviceInfo = &default_devices;
    return page.js.local.?.resolvePromise(devices);
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(MediaDevices);

    pub const Meta = struct {
        pub const name = "MediaDevices";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const enumerateDevices = bridge.function(MediaDevices.enumerateDevices, .{});
};
