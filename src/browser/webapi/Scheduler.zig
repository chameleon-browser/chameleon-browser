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

const Scheduler = @This();

_pad: bool = false,

pub const init: Scheduler = .{};

const PostTaskOpts = struct {
    priority: ?[]const u8 = null,
    delay: ?u32 = null,
};

pub fn postTask(_: *const Scheduler, task: js.Function, _: ?PostTaskOpts, page: *Page) !js.Promise {
    _ = task.call(js.Value, .{}) catch {};
    return page.js.local.?.resolvePromise(null);
}

pub fn yieldTask(_: *const Scheduler, page: *Page) !js.Promise {
    return page.js.local.?.resolvePromise(null);
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(Scheduler);

    pub const Meta = struct {
        pub const name = "Scheduler";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const postTask = bridge.function(Scheduler.postTask, .{});
    pub const yield = bridge.function(Scheduler.yieldTask, .{});
};
