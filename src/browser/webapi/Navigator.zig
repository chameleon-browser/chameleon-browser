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
const js = @import("../js/js.zig");
const Page = @import("../Page.zig");
const PluginArray = @import("PluginArray.zig");
const MediaDevices = @import("MediaDevices.zig");
const Permissions = @import("Permissions.zig");

pub fn registerTypes() []const type {
    return &.{
        Navigator,
        NavigatorUAData,
    };
}

const Navigator = @This();
_pad: bool = false,
_plugins: PluginArray = .{},
_mime_types: PluginArray.MimeTypeArray = .{},
_media_devices: MediaDevices = .init,
_permissions: Permissions = .init,

pub const init: Navigator = .{};

pub fn getUserAgent(_: *const Navigator, page: *Page) []const u8 {
    return page._session.userAgent();
}

pub fn getLanguage(_: *const Navigator, page: *Page) []const u8 {
    return primaryLanguageFromAcceptLanguage(page._session.acceptLanguageHeader());
}

pub fn getLanguages(_: *const Navigator, page: *Page) ![]const []const u8 {
    return languagesFromAcceptLanguage(page.call_arena, page._session.acceptLanguageHeader());
}

pub fn getPlatform(_: *const Navigator, page: *Page) []const u8 {
    return page._session.navigatorPlatform();
}

pub fn getVendor(_: *const Navigator, page: *Page) []const u8 {
    return page._session.navigatorVendor();
}

pub fn getAppVersion(_: *const Navigator, page: *Page) []const u8 {
    return page._session.navigatorAppVersion();
}

pub fn getUserAgentData(_: *const Navigator, page: *Page) !*NavigatorUAData {
    return NavigatorUAData.init(page);
}

/// Returns whether Java is enabled (always false)
pub fn javaEnabled(_: *const Navigator) bool {
    return false;
}

pub fn getPlugins(self: *Navigator) *PluginArray {
    return &self._plugins;
}

pub fn getMimeTypes(self: *Navigator) *PluginArray.MimeTypeArray {
    return &self._mime_types;
}

pub fn getPermissions(self: *Navigator) *Permissions {
    return &self._permissions;
}

pub fn getMediaDevices(self: *Navigator) *MediaDevices {
    return &self._media_devices;
}

pub fn getWebdriver(_: *const Navigator) ?bool {
    return null;
}

pub fn getBattery(_: *const Navigator, page: *Page) !js.Promise {
    const BatteryStatus = struct {
        charging: bool,
        chargingTime: i32,
        dischargingTime: i32,
        level: f64,
    };

    const status: BatteryStatus = .{
        .charging = true,
        .chargingTime = @as(i32, 0),
        .dischargingTime = @as(i32, 0),
        .level = 1.0,
    };
    return page.js.local.?.resolvePromise(status);
}

pub fn registerProtocolHandler(_: *const Navigator, scheme: []const u8, url: [:0]const u8, page: *const Page) !void {
    try validateProtocolHandlerScheme(scheme);
    try validateProtocolHandlerURL(url, page);
}
pub fn unregisterProtocolHandler(_: *const Navigator, scheme: []const u8, url: [:0]const u8, page: *const Page) !void {
    try validateProtocolHandlerScheme(scheme);
    try validateProtocolHandlerURL(url, page);
}

pub fn sendBeacon(_: *const Navigator, _: []const u8, _: ?js.Value.Temp) bool {
    return true;
}

fn validateProtocolHandlerScheme(scheme: []const u8) !void {
    const allowed = std.StaticStringMap(void).initComptime(.{
        .{ "bitcoin", {} },
        .{ "cabal", {} },
        .{ "dat", {} },
        .{ "did", {} },
        .{ "dweb", {} },
        .{ "ethereum", .{} },
        .{ "ftp", {} },
        .{ "ftps", {} },
        .{ "geo", {} },
        .{ "im", {} },
        .{ "ipfs", {} },
        .{ "ipns", .{} },
        .{ "irc", {} },
        .{ "ircs", {} },
        .{ "hyper", {} },
        .{ "magnet", {} },
        .{ "mailto", {} },
        .{ "matrix", {} },
        .{ "mms", {} },
        .{ "news", {} },
        .{ "nntp", {} },
        .{ "openpgp4fpr", {} },
        .{ "sftp", {} },
        .{ "sip", {} },
        .{ "sms", {} },
        .{ "smsto", {} },
        .{ "ssb", {} },
        .{ "ssh", {} },
        .{ "tel", {} },
        .{ "urn", {} },
        .{ "webcal", {} },
        .{ "wtai", {} },
        .{ "xmpp", {} },
    });
    if (allowed.has(scheme)) {
        return;
    }

    if (scheme.len < 5 or !std.mem.startsWith(u8, scheme, "web+")) {
        return error.SecurityError;
    }
    for (scheme[4..]) |b| {
        if (std.ascii.isLower(b) == false) {
            return error.SecurityError;
        }
    }
}

fn validateProtocolHandlerURL(url: [:0]const u8, page: *const Page) !void {
    if (std.mem.indexOf(u8, url, "%s") == null) {
        return error.SyntaxError;
    }
    if (try page.isSameOrigin(url) == false) {
        return error.SyntaxError;
    }
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(Navigator);

    pub const Meta = struct {
        pub const name = "Navigator";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
        pub const empty_with_no_proto = true;
    };

    // Read-only properties
    pub const userAgent = bridge.accessor(Navigator.getUserAgent, null, .{});
    pub const appName = bridge.property("Netscape", .{ .template = false });
    pub const appCodeName = bridge.property("Netscape", .{ .template = false });
    pub const appVersion = bridge.accessor(Navigator.getAppVersion, null, .{});
    pub const platform = bridge.accessor(Navigator.getPlatform, null, .{});
    pub const language = bridge.accessor(Navigator.getLanguage, null, .{});
    pub const languages = bridge.accessor(Navigator.getLanguages, null, .{});
    pub const onLine = bridge.property(true, .{ .template = false });
    pub const cookieEnabled = bridge.property(true, .{ .template = false });
    pub const hardwareConcurrency = bridge.property(4, .{ .template = false });
    pub const maxTouchPoints = bridge.property(0, .{ .template = false });
    pub const cpuClass = bridge.property(null, .{ .template = false });
    pub const oscpu = bridge.property(null, .{ .template = false });
    pub const vendor = bridge.accessor(Navigator.getVendor, null, .{});
    pub const product = bridge.property("Gecko", .{ .template = false });
    pub const plugins = bridge.accessor(Navigator.getPlugins, null, .{});
    pub const mimeTypes = bridge.accessor(Navigator.getMimeTypes, null, .{});
    pub const mediaDevices = bridge.accessor(Navigator.getMediaDevices, null, .{});
    pub const permissions = bridge.accessor(Navigator.getPermissions, null, .{});
    pub const getBattery = bridge.function(Navigator.getBattery, .{});
    pub const pdfViewerEnabled = bridge.property(true, .{ .template = false });
    pub const doNotTrack = bridge.property(null, .{ .template = false });
    pub const msDoNotTrack = bridge.property(null, .{ .template = false });
    pub const globalPrivacyControl = bridge.property(true, .{ .template = false });
    pub const deviceMemory = bridge.property(8.0, .{ .template = false });
    pub const productSub = bridge.property("20030107", .{ .template = false });
    pub const webdriver = bridge.property(false, .{ .template = false });
    pub const registerProtocolHandler = bridge.function(Navigator.registerProtocolHandler, .{ .dom_exception = true });
    pub const unregisterProtocolHandler = bridge.function(Navigator.unregisterProtocolHandler, .{ .dom_exception = true });
    pub const sendBeacon = bridge.function(Navigator.sendBeacon, .{});
    pub const userAgentData = bridge.accessor(Navigator.getUserAgentData, null, .{});

    // Methods
    pub const javaEnabled = bridge.function(Navigator.javaEnabled, .{});
};

const BrandVersion = struct {
    brand: []const u8,
    version: []const u8,
};

const NavigatorUAData = struct {
    _pad: bool = false,

    pub fn init(page: *Page) !*NavigatorUAData {
        const ua = try page.arena.create(NavigatorUAData);
        ua.* = .{};
        return ua;
    }

    pub fn getBrands(_: *const NavigatorUAData, page: *Page) ![]const BrandVersion {
        return parseSecChUaBrands(page.call_arena, page._session.secChUaHeader());
    }

    pub fn getMobile(_: *const NavigatorUAData, page: *Page) bool {
        return std.mem.eql(u8, page._session.secChUaMobileHeader(), "sec-ch-ua-mobile: ?1");
    }

    pub fn getPlatform(_: *const NavigatorUAData, page: *Page) []const u8 {
        return parseSecChUaPlatform(page._session.secChUaPlatformHeader());
    }

    pub fn toJSON(self: *const NavigatorUAData, page: *Page) !struct {
        brands: []const BrandVersion,
        mobile: bool,
        platform: []const u8,
    } {
        return .{
            .brands = try self.getBrands(page),
            .mobile = self.getMobile(page),
            .platform = self.getPlatform(page),
        };
    }

    pub fn getHighEntropyValues(self: *const NavigatorUAData, hints: []const []const u8, page: *Page) !js.Promise {
        var out: struct {
            architecture: ?[]const u8 = null,
            bitness: ?[]const u8 = null,
            brands: ?[]const BrandVersion = null,
            fullVersionList: ?[]const BrandVersion = null,
            mobile: ?bool = null,
            model: ?[]const u8 = null,
            platform: ?[]const u8 = null,
            platformVersion: ?[]const u8 = null,
            uaFullVersion: ?[]const u8 = null,
            wow64: ?bool = null,
        } = .{};

        for (hints) |hint| {
            if (std.mem.eql(u8, hint, "architecture")) {
                out.architecture = "x86";
                continue;
            }
            if (std.mem.eql(u8, hint, "bitness")) {
                out.bitness = "64";
                continue;
            }
            if (std.mem.eql(u8, hint, "brands")) {
                out.brands = try self.getBrands(page);
                continue;
            }
            if (std.mem.eql(u8, hint, "fullVersionList")) {
                out.fullVersionList = try self.getBrands(page);
                continue;
            }
            if (std.mem.eql(u8, hint, "mobile")) {
                out.mobile = self.getMobile(page);
                continue;
            }
            if (std.mem.eql(u8, hint, "model")) {
                out.model = "";
                continue;
            }
            if (std.mem.eql(u8, hint, "platform")) {
                out.platform = self.getPlatform(page);
                continue;
            }
            if (std.mem.eql(u8, hint, "platformVersion")) {
                out.platformVersion = parsePlatformVersion(page._session.userAgent());
                continue;
            }
            if (std.mem.eql(u8, hint, "uaFullVersion")) {
                out.uaFullVersion = parseUaFullVersion(page._session.userAgent());
                continue;
            }
            if (std.mem.eql(u8, hint, "wow64")) {
                out.wow64 = false;
                continue;
            }
        }

        return page.js.local.?.resolvePromise(out);
    }

    pub const JsApi = struct {
        pub const bridge = js.Bridge(NavigatorUAData);

        pub const Meta = struct {
            pub const name = "NavigatorUAData";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const brands = bridge.accessor(NavigatorUAData.getBrands, null, .{});
        pub const mobile = bridge.accessor(NavigatorUAData.getMobile, null, .{});
        pub const platform = bridge.accessor(NavigatorUAData.getPlatform, null, .{});
        pub const getHighEntropyValues = bridge.function(NavigatorUAData.getHighEntropyValues, .{});
        pub const toJSON = bridge.function(NavigatorUAData.toJSON, .{});
    };
};

fn primaryLanguageFromAcceptLanguage(header: []const u8) []const u8 {
    const value = acceptLanguageValue(header);
    if (value.len == 0) return "en-US";

    var it = std.mem.splitScalar(u8, value, ',');
    const first_raw = std.mem.trim(u8, it.first(), " ");
    if (first_raw.len == 0) return "en-US";

    const semi = std.mem.indexOfScalar(u8, first_raw, ';') orelse first_raw.len;
    const first = std.mem.trim(u8, first_raw[0..semi], " ");
    if (first.len == 0) return "en-US";
    return first;
}

fn languagesFromAcceptLanguage(arena: std.mem.Allocator, header: []const u8) ![]const []const u8 {
    const value = acceptLanguageValue(header);
    if (value.len == 0) {
        const out = try arena.alloc([]const u8, 1);
        out[0] = "en-US";
        return out;
    }

    var list = std.ArrayList([]const u8).empty;
    var it = std.mem.splitScalar(u8, value, ',');
    while (it.next()) |entry_raw| {
        const entry_trim = std.mem.trim(u8, entry_raw, " ");
        if (entry_trim.len == 0) continue;
        const semi = std.mem.indexOfScalar(u8, entry_trim, ';') orelse entry_trim.len;
        const lang = std.mem.trim(u8, entry_trim[0..semi], " ");
        if (lang.len == 0) continue;
        try list.append(arena, lang);
    }

    if (list.items.len == 0) {
        const out = try arena.alloc([]const u8, 1);
        out[0] = "en-US";
        return out;
    }
    return list.toOwnedSlice(arena);
}

fn acceptLanguageValue(header: []const u8) []const u8 {
    if (std.mem.indexOfScalar(u8, header, ':')) |idx| {
        return std.mem.trim(u8, header[idx + 1 ..], " ");
    }
    return std.mem.trim(u8, header, " ");
}

fn parseSecChUaBrands(arena: std.mem.Allocator, header: []const u8) ![]const BrandVersion {
    const value = if (std.mem.indexOfScalar(u8, header, ':')) |i| std.mem.trim(u8, header[i + 1 ..], " ") else header;
    var brands: std.ArrayList(BrandVersion) = .empty;

    var idx: usize = 0;
    while (idx < value.len) {
        const q1_rel = std.mem.indexOfScalarPos(u8, value, idx, '"') orelse break;
        const q2_rel = std.mem.indexOfScalarPos(u8, value, q1_rel + 1, '"') orelse break;
        const brand = value[q1_rel + 1 .. q2_rel];

        const marker = ";v=\"";
        const v_rel = std.mem.indexOfPos(u8, value, q2_rel, marker) orelse break;
        const v_start = v_rel + marker.len;
        const v_end = std.mem.indexOfScalarPos(u8, value, v_start, '"') orelse break;
        const version = value[v_start..v_end];

        try brands.append(arena, .{ .brand = brand, .version = version });
        idx = v_end + 1;
    }
    return brands.items;
}

fn parseSecChUaPlatform(header: []const u8) []const u8 {
    const value = if (std.mem.indexOfScalar(u8, header, ':')) |i| std.mem.trim(u8, header[i + 1 ..], " ") else header;
    const q1 = std.mem.indexOfScalar(u8, value, '"') orelse return "Unknown";
    const q2 = std.mem.indexOfScalarPos(u8, value, q1 + 1, '"') orelse return "Unknown";
    return value[q1 + 1 .. q2];
}

fn parsePlatformVersion(user_agent: []const u8) []const u8 {
    // Windows NT 10.0 in UA → could be Win10 or Win11. Chrome 116+ uses
    // platformVersion "15.0.0" for Win11 and "10.0.0" for Win10.
    // Since we can't distinguish from UA alone, default to Win10 ("10.0.0")
    // which is the safer choice (more common).
    if (std.mem.indexOf(u8, user_agent, "Windows NT 10.0") != null) return "10.0.0";
    if (std.mem.indexOf(u8, user_agent, "Windows NT 6.3") != null) return "6.3.0";
    if (std.mem.indexOf(u8, user_agent, "Windows NT 6.2") != null) return "6.2.0";
    if (std.mem.indexOf(u8, user_agent, "Windows NT 6.1") != null) return "6.1.0";

    // macOS: "Macintosh; Intel Mac OS X 10_15_7" → platformVersion "14.6.1"
    // Chrome reports the *actual* macOS version (not the UA-frozen one),
    // so we pick a realistic recent version.
    if (std.mem.indexOf(u8, user_agent, "Macintosh") != null) return "14.6.1";

    // Linux: kernel version style
    if (std.mem.indexOf(u8, user_agent, "Linux") != null) return "6.5.0";

    // Fallback
    return "10.0.0";
}

fn parseUaFullVersion(user_agent: []const u8) []const u8 {
    const token = if (std.mem.indexOf(u8, user_agent, "Edg/") != null)
        "Edg/"
    else if (std.mem.indexOf(u8, user_agent, "Chrome/") != null)
        "Chrome/"
    else if (std.mem.indexOf(u8, user_agent, "Version/") != null)
        "Version/"
    else
        return "0.0.0.0";

    const start = std.mem.indexOf(u8, user_agent, token).? + token.len;
    const rest = user_agent[start..];
    const end = std.mem.indexOfScalar(u8, rest, ' ') orelse rest.len;
    return rest[0..end];
}

test "navigator language helpers parse accept-language" {
    const testing = std.testing;

    try testing.expectEqualStrings("zh-CN", primaryLanguageFromAcceptLanguage("accept-language: zh-CN,zh;q=0.9,en;q=0.8"));
    try testing.expectEqualStrings("en-US", primaryLanguageFromAcceptLanguage("accept-language:   "));
}

test "navigator languages helper returns ordered tags" {
    const testing = std.testing;
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const out = try languagesFromAcceptLanguage(arena.allocator(), "accept-language: zh-CN, zh;q=0.9, en;q=0.8");
    try testing.expectEqual(@as(usize, 3), out.len);
    try testing.expectEqualStrings("zh-CN", out[0]);
    try testing.expectEqualStrings("zh", out[1]);
    try testing.expectEqualStrings("en", out[2]);
}
