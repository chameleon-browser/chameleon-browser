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
    return &.{ Chrome, Runtime, App, WebStore };
}

const Chrome = @This();

_runtime: Runtime = .init,
_app: App = .init,
_webstore: WebStore = .init,

pub const init: Chrome = .{};

pub fn getRuntime(self: *Chrome) *Runtime {
    return &self._runtime;
}

pub fn getApp(self: *Chrome) *App {
    return &self._app;
}

pub fn getWebstore(self: *Chrome) *WebStore {
    return &self._webstore;
}

pub fn csi(_: *const Chrome) struct {
    onloadT: i64,
    startE: i64,
    pageT: i64,
    tran: i32,
} {
    const now = std.time.milliTimestamp();
    return .{
        .onloadT = now,
        .startE = now - 5,
        .pageT = now - 10,
        .tran = 15,
    };
}

pub fn loadTimes(_: *const Chrome) struct {
    requestTime: f64,
    startLoadTime: f64,
    commitLoadTime: f64,
    finishDocumentLoadTime: f64,
    finishLoadTime: f64,
    firstPaintTime: f64,
    firstPaintAfterLoadTime: f64,
    navigationType: []const u8,
    wasFetchedViaSpdy: bool,
    wasNpnNegotiated: bool,
    npnNegotiatedProtocol: []const u8,
    wasAlternateProtocolAvailable: bool,
    connectionInfo: []const u8,
} {
    const now_ms = @as(f64, @floatFromInt(std.time.milliTimestamp()));
    const now_s = now_ms / 1000.0;
    return .{
        .requestTime = now_s - 0.2,
        .startLoadTime = now_s - 0.18,
        .commitLoadTime = now_s - 0.12,
        .finishDocumentLoadTime = now_s - 0.04,
        .finishLoadTime = now_s,
        .firstPaintTime = now_s - 0.03,
        .firstPaintAfterLoadTime = 0,
        .navigationType = "Other",
        .wasFetchedViaSpdy = true,
        .wasNpnNegotiated = true,
        .npnNegotiatedProtocol = "h2",
        .wasAlternateProtocolAvailable = false,
        .connectionInfo = "h2",
    };
}

pub const Runtime = struct {
    _pad: bool = false,

    pub const init: Runtime = .{};

    pub fn connect(_: *const Runtime, extension_id: ?[]const u8) !void {
        if (extension_id == null or extension_id.?.len == 0) {
            return error.ChromeRuntimeConnectRequiresExtensionId;
        }
        return error.ChromeRuntimeApiNotSupported;
    }

    pub fn sendMessage(_: *const Runtime) !void {
        return error.ChromeRuntimeSendMessageRequiresExtensionId;
    }

    pub const JsApi = struct {
        pub const bridge = js.Bridge(Runtime);

        pub const Meta = struct {
            pub const name = "Runtime";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const connect = bridge.function(Runtime.connect, .{});
        pub const sendMessage = bridge.function(Runtime.sendMessage, .{});
    };
};

pub const App = struct {
    _pad: bool = false,

    pub const init: App = .{};

    pub const JsApi = struct {
        pub const bridge = js.Bridge(App);

        pub const Meta = struct {
            pub const name = "App";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const isInstalled = bridge.property(false, .{ .template = false });
    };
};

pub const WebStore = struct {
    _pad: bool = false,

    pub const init: WebStore = .{};

    pub const JsApi = struct {
        pub const bridge = js.Bridge(WebStore);

        pub const Meta = struct {
            pub const name = "WebStore";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const onInstallStage = bridge.property("disabled", .{ .template = false });
    };
};

pub const JsApi = struct {
    pub const bridge = js.Bridge(Chrome);

    pub const Meta = struct {
        pub const name = "Chrome";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
        pub const empty_with_no_proto = true;
    };

    pub const runtime = bridge.accessor(Chrome.getRuntime, null, .{});
    pub const app = bridge.accessor(Chrome.getApp, null, .{});
    pub const webstore = bridge.accessor(Chrome.getWebstore, null, .{});
    pub const csi = bridge.function(Chrome.csi, .{});
    pub const loadTimes = bridge.function(Chrome.loadTimes, .{});
};
