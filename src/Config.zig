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
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;

const log = @import("log.zig");
const dump = @import("browser/dump.zig");

pub const RunMode = enum {
    help,
    fetch,
    serve,
    version,
};

mode: Mode,
exec_name: []const u8,
http_headers: HttpHeaders,
default_browser_fingerprint: [:0]const u8,

const Config = @This();

pub fn init(allocator: Allocator, exec_name: []const u8, mode: Mode) !Config {
    var config = Config{
        .mode = mode,
        .exec_name = exec_name,
        .http_headers = undefined,
        .default_browser_fingerprint = randomBrowserFingerprint(),
    };
    config.http_headers = try HttpHeaders.init(allocator, &config);
    return config;
}

pub fn deinit(self: *const Config, allocator: Allocator) void {
    self.http_headers.deinit(allocator);
}

pub fn tlsVerifyHost(self: *const Config) bool {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.tls_verify_host,
        else => unreachable,
    };
}

pub fn obeyRobots(self: *const Config) bool {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.obey_robots,
        else => unreachable,
    };
}

pub fn httpProxy(self: *const Config) ?[:0]const u8 {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.http_proxy,
        else => unreachable,
    };
}

pub fn proxyBearerToken(self: *const Config) ?[:0]const u8 {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.proxy_bearer_token,
        .help, .version => null,
    };
}

pub fn httpMaxConcurrent(self: *const Config) u8 {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.http_max_concurrent orelse 10,
        else => unreachable,
    };
}

pub fn httpMaxHostOpen(self: *const Config) u8 {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.http_max_host_open orelse 4,
        else => unreachable,
    };
}

pub fn httpConnectTimeout(self: *const Config) u31 {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.http_connect_timeout orelse 0,
        else => unreachable,
    };
}

pub fn httpTimeout(self: *const Config) u31 {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.http_timeout orelse 5000,
        else => unreachable,
    };
}

pub fn httpMaxRedirects(_: *const Config) u8 {
    return 10;
}

pub fn httpMaxResponseSize(self: *const Config) ?usize {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.http_max_response_size,
        else => unreachable,
    };
}

pub fn logLevel(self: *const Config) ?log.Level {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.log_level,
        else => unreachable,
    };
}

pub fn logFormat(self: *const Config) ?log.Format {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.log_format,
        else => unreachable,
    };
}

pub fn logFilterScopes(self: *const Config) ?[]const log.Scope {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.log_filter_scopes,
        else => unreachable,
    };
}

pub fn userAgentSuffix(self: *const Config) ?[]const u8 {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.user_agent_suffix,
        .help, .version => null,
    };
}

pub fn browserFingerprint(self: *const Config) [:0]const u8 {
    return switch (self.mode) {
        inline .serve, .fetch => |opts| opts.common.browser orelse self.default_browser_fingerprint,
        .help, .version => self.default_browser_fingerprint,
    };
}

pub fn browserProfile(self: *const Config) BrowserProfile {
    return browserProfileForFingerprint(self.browserFingerprint()) orelse unreachable;
}

pub const Mode = union(RunMode) {
    help: bool, // false when being printed because of an error
    fetch: Fetch,
    serve: Serve,
    version: void,
};

pub const Serve = struct {
    host: []const u8 = "127.0.0.1",
    port: u16 = 9222,
    timeout: u31 = 10,
    max_connections: u16 = 16,
    max_tabs_per_connection: u16 = 8,
    max_memory_per_tab: u64 = 512 * 1024 * 1024,
    max_pending_connections: u16 = 128,
    common: Common = .{},
};

pub const Fetch = struct {
    url: [:0]const u8,
    dump: bool = false,
    common: Common = .{},
    withbase: bool = false,
    strip: dump.Opts.Strip = .{},
};

pub const Common = struct {
    obey_robots: bool = false,
    proxy_bearer_token: ?[:0]const u8 = null,
    http_proxy: ?[:0]const u8 = null,
    http_max_concurrent: ?u8 = null,
    http_max_host_open: ?u8 = null,
    http_timeout: ?u31 = null,
    http_connect_timeout: ?u31 = null,
    http_max_response_size: ?usize = null,
    tls_verify_host: bool = true,
    log_level: ?log.Level = null,
    log_format: ?log.Format = null,
    log_filter_scopes: ?[]log.Scope = null,
    user_agent_suffix: ?[]const u8 = null,
    browser: ?[:0]const u8 = null,
};

const browser_fingerprints = [_][:0]const u8{
    "chrome99",
    "chrome100",
    "chrome101",
    "chrome104",
    "chrome107",
    "chrome110",
    "chrome116",
    "chrome99_android",
    "edge99",
    "edge101",
    "safari15_3",
    "safari15_5",
};

pub const BrowserProfile = struct {
    user_agent: [:0]const u8,
    sec_ch_ua_header: [:0]const u8,
    sec_ch_ua_mobile_header: [:0]const u8,
    sec_ch_ua_platform_header: [:0]const u8,
    accept_language_header: [:0]const u8,
    navigator_platform: [:0]const u8,
    navigator_vendor: [:0]const u8,
    navigator_app_version: [:0]const u8,
    cdp_product: [:0]const u8,
    cdp_user_agent: [:0]const u8,
};

const default_browser_fingerprints = [_][:0]const u8{
    "chrome99",
    "chrome100",
    "chrome101",
    "chrome104",
    "chrome107",
    "chrome110",
    "chrome116",
    "chrome99_android",
    "edge99",
    "edge101",
};

fn randomBrowserFingerprint() [:0]const u8 {
    const idx = std.crypto.random.int(u64) % default_browser_fingerprints.len;
    return default_browser_fingerprints[@intCast(idx)];
}

const GpuProfile = struct {
    vendor: [:0]const u8,
    renderer: [:0]const u8,
};

/// Pre-collected GPU fingerprints from real-world browsers.
/// Each entry represents a (vendor, renderer) pair as reported by
/// WebGL's UNMASKED_VENDOR_WEBGL / UNMASKED_RENDERER_WEBGL.
const gpu_profiles = [_]GpuProfile{
    .{ .vendor = "Google Inc. (NVIDIA)", .renderer = "ANGLE (NVIDIA, NVIDIA GeForce GTX 1650 Direct3D11 vs_5_0 ps_5_0, D3D11)" },
    .{ .vendor = "Google Inc. (NVIDIA)", .renderer = "ANGLE (NVIDIA, NVIDIA GeForce RTX 3060 Direct3D11 vs_5_0 ps_5_0, D3D11)" },
    .{ .vendor = "Google Inc. (NVIDIA)", .renderer = "ANGLE (NVIDIA, NVIDIA GeForce GTX 1060 6GB Direct3D11 vs_5_0 ps_5_0, D3D11)" },
    .{ .vendor = "Google Inc. (NVIDIA)", .renderer = "ANGLE (NVIDIA, NVIDIA GeForce RTX 2060 SUPER Direct3D11 vs_5_0 ps_5_0, D3D11)" },
    .{ .vendor = "Google Inc. (NVIDIA)", .renderer = "ANGLE (NVIDIA, NVIDIA GeForce RTX 3070 Direct3D11 vs_5_0 ps_5_0, D3D11)" },
    .{ .vendor = "Google Inc. (NVIDIA)", .renderer = "ANGLE (NVIDIA, NVIDIA GeForce GTX 1080 Ti Direct3D11 vs_5_0 ps_5_0, D3D11)" },
    .{ .vendor = "Google Inc. (AMD)", .renderer = "ANGLE (AMD, AMD Radeon RX 580 Direct3D11 vs_5_0 ps_5_0, D3D11)" },
    .{ .vendor = "Google Inc. (AMD)", .renderer = "ANGLE (AMD, AMD Radeon RX 5700 XT Direct3D11 vs_5_0 ps_5_0, D3D11)" },
    .{ .vendor = "Google Inc. (AMD)", .renderer = "ANGLE (AMD, AMD Radeon(TM) Graphics Direct3D11 vs_5_0 ps_5_0, D3D11)" },
    .{ .vendor = "Google Inc. (Intel)", .renderer = "ANGLE (Intel, Intel(R) UHD Graphics 630 Direct3D11 vs_5_0 ps_5_0, D3D11)" },
    .{ .vendor = "Google Inc. (Intel)", .renderer = "ANGLE (Intel, Intel(R) UHD Graphics 620 Direct3D11 vs_5_0 ps_5_0, D3D11)" },
    .{ .vendor = "Google Inc. (Intel)", .renderer = "ANGLE (Intel, Intel(R) Iris(R) Xe Graphics Direct3D11 vs_5_0 ps_5_0, D3D11)" },
};

fn randomGpuProfile() GpuProfile {
    const idx = std.crypto.random.int(u64) % gpu_profiles.len;
    return gpu_profiles[@intCast(idx)];
}

fn isSupportedBrowserFingerprint(value: []const u8) bool {
    return browserProfileForFingerprint(value) != null;
}

fn browserProfileForFingerprint(fingerprint: []const u8) ?BrowserProfile {
    if (std.mem.eql(u8, fingerprint, "chrome99")) {
        return browserProfileChrome("99.0.4844.51", "99", "99.0.4844.51");
    }
    if (std.mem.eql(u8, fingerprint, "chrome100")) {
        return browserProfileChrome("100.0.4896.127", "100", "100.0.4896.127");
    }
    if (std.mem.eql(u8, fingerprint, "chrome101")) {
        return browserProfileChrome("101.0.4951.67", "101", "101.0.4951.67");
    }
    if (std.mem.eql(u8, fingerprint, "chrome104")) {
        return browserProfileChrome("104.0.0.0", "104", "104.0.0.0");
    }
    if (std.mem.eql(u8, fingerprint, "chrome107")) {
        return browserProfileChrome("107.0.0.0", "107", "107.0.0.0");
    }
    if (std.mem.eql(u8, fingerprint, "chrome110")) {
        return browserProfileChrome("110.0.0.0", "110", "110.0.0.0");
    }
    if (std.mem.eql(u8, fingerprint, "chrome116")) {
        return browserProfileChrome("116.0.5845.180", "116", "116.0.5845.180");
    }
    if (std.mem.eql(u8, fingerprint, "chrome99_android")) {
        return .{
            .user_agent = "Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.58 Mobile Safari/537.36",
            .sec_ch_ua_header = "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Chromium\";v=\"99\", \"Google Chrome\";v=\"99\"",
            .sec_ch_ua_mobile_header = "sec-ch-ua-mobile: ?1",
            .sec_ch_ua_platform_header = "sec-ch-ua-platform: \"Android\"",
            .accept_language_header = "Accept-Language: en-US,en;q=0.9",
            .navigator_platform = "Linux armv8l",
            .navigator_vendor = "Google Inc.",
            .navigator_app_version = "5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.58 Mobile Safari/537.36",
            .cdp_product = "Chrome/99.0.4844.58",
            .cdp_user_agent = "Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.58 Mobile Safari/537.36",
        };
    }
    if (std.mem.eql(u8, fingerprint, "edge99")) {
        return .{
            .user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36 Edg/99.0.1150.30",
            .sec_ch_ua_header = "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Chromium\";v=\"99\", \"Microsoft Edge\";v=\"99\"",
            .sec_ch_ua_mobile_header = "sec-ch-ua-mobile: ?0",
            .sec_ch_ua_platform_header = "sec-ch-ua-platform: \"Windows\"",
            .accept_language_header = "Accept-Language: en-US,en;q=0.9",
            .navigator_platform = "Win32",
            .navigator_vendor = "Google Inc.",
            .navigator_app_version = "5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36 Edg/99.0.1150.30",
            .cdp_product = "Chrome/99.0.4844.51",
            .cdp_user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36 Edg/99.0.1150.30",
        };
    }
    if (std.mem.eql(u8, fingerprint, "edge101")) {
        return .{
            .user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.64 Safari/537.36 Edg/101.0.1210.47",
            .sec_ch_ua_header = "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Chromium\";v=\"101\", \"Microsoft Edge\";v=\"101\"",
            .sec_ch_ua_mobile_header = "sec-ch-ua-mobile: ?0",
            .sec_ch_ua_platform_header = "sec-ch-ua-platform: \"Windows\"",
            .accept_language_header = "Accept-Language: en-US,en;q=0.9",
            .navigator_platform = "Win32",
            .navigator_vendor = "Google Inc.",
            .navigator_app_version = "5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.64 Safari/537.36 Edg/101.0.1210.47",
            .cdp_product = "Chrome/101.0.4951.64",
            .cdp_user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.64 Safari/537.36 Edg/101.0.1210.47",
        };
    }
    if (std.mem.eql(u8, fingerprint, "safari15_3")) {
        return .{
            .user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 11_6_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Safari/605.1.15",
            .sec_ch_ua_header = "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Safari\";v=\"15\"",
            .sec_ch_ua_mobile_header = "sec-ch-ua-mobile: ?0",
            .sec_ch_ua_platform_header = "sec-ch-ua-platform: \"macOS\"",
            .accept_language_header = "Accept-Language: en-US,en;q=0.9",
            .navigator_platform = "MacIntel",
            .navigator_vendor = "Apple Computer, Inc.",
            .navigator_app_version = "5.0 (Macintosh; Intel Mac OS X 11_6_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Safari/605.1.15",
            .cdp_product = "Safari/15.3",
            .cdp_user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 11_6_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Safari/605.1.15",
        };
    }
    if (std.mem.eql(u8, fingerprint, "safari15_5")) {
        return .{
            .user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15",
            .sec_ch_ua_header = "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Safari\";v=\"15\"",
            .sec_ch_ua_mobile_header = "sec-ch-ua-mobile: ?0",
            .sec_ch_ua_platform_header = "sec-ch-ua-platform: \"macOS\"",
            .accept_language_header = "Accept-Language: en-US,en;q=0.9",
            .navigator_platform = "MacIntel",
            .navigator_vendor = "Apple Computer, Inc.",
            .navigator_app_version = "5.0 (Macintosh; Intel Mac OS X 12_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15",
            .cdp_product = "Safari/15.5",
            .cdp_user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15",
        };
    }
    return null;
}

fn browserProfileChrome(comptime full_version: []const u8, comptime major: []const u8, comptime cdp_version: []const u8) BrowserProfile {
    const user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/" ++ full_version ++ " Safari/537.36";
    const sec_ch_ua_header = if (std.mem.eql(u8, major, "99"))
        "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Chromium\";v=\"99\", \"Google Chrome\";v=\"99\""
    else if (std.mem.eql(u8, major, "100"))
        "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Chromium\";v=\"100\", \"Google Chrome\";v=\"100\""
    else if (std.mem.eql(u8, major, "101"))
        "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Chromium\";v=\"101\", \"Google Chrome\";v=\"101\""
    else if (std.mem.eql(u8, major, "104"))
        "sec-ch-ua: \"Chromium\";v=\"104\", \" Not A;Brand\";v=\"99\", \"Google Chrome\";v=\"104\""
    else if (std.mem.eql(u8, major, "107"))
        "sec-ch-ua: \"Google Chrome\";v=\"107\", \"Chromium\";v=\"107\", \"Not=A?Brand\";v=\"24\""
    else if (std.mem.eql(u8, major, "110"))
        "sec-ch-ua: \"Chromium\";v=\"110\", \"Not A(Brand\";v=\"24\", \"Google Chrome\";v=\"110\""
    else if (std.mem.eql(u8, major, "116"))
        "sec-ch-ua: \"Chromium\";v=\"116\", \"Not)A;Brand\";v=\"24\", \"Google Chrome\";v=\"116\""
    else
        "sec-ch-ua: \"Chromium\";v=\"99\", \"Google Chrome\";v=\"99\", \" Not A;Brand\";v=\"99\"";

    return .{
        .user_agent = user_agent,
        .sec_ch_ua_header = sec_ch_ua_header,
        .sec_ch_ua_mobile_header = "sec-ch-ua-mobile: ?0",
        .sec_ch_ua_platform_header = "sec-ch-ua-platform: \"Windows\"",
        .accept_language_header = "Accept-Language: en-US,en;q=0.9",
        .navigator_platform = "Win32",
        .navigator_vendor = "Google Inc.",
        .navigator_app_version = "5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/" ++ full_version ++ " Safari/537.36",
        .cdp_product = "Chrome/" ++ cdp_version,
        .cdp_user_agent = user_agent,
    };
}

/// Pre-formatted HTTP headers for reuse across Http and Client.
/// Must be initialized with an allocator that outlives all HTTP connections.
pub const HttpHeaders = struct {
    user_agent: [:0]const u8,
    user_agent_is_allocated: bool,
    user_agent_header: [:0]const u8,
    sec_ch_ua_header: [:0]const u8,
    sec_ch_ua_mobile_header: [:0]const u8,
    sec_ch_ua_platform_header: [:0]const u8,
    accept_language_header: [:0]const u8,
    navigator_platform: [:0]const u8,
    navigator_vendor: [:0]const u8,
    navigator_app_version: [:0]const u8,
    cdp_product: [:0]const u8,
    cdp_user_agent: [:0]const u8,
    gpu_vendor: [:0]const u8,
    gpu_renderer: [:0]const u8,

    proxy_bearer_header: ?[:0]const u8,

    pub fn init(allocator: Allocator, config: *const Config) !HttpHeaders {
        const profile = config.browserProfile();
        const user_agent: [:0]const u8 = if (config.userAgentSuffix()) |suffix|
            try std.fmt.allocPrintSentinel(allocator, "{s} {s}", .{ profile.user_agent, suffix }, 0)
        else
            profile.user_agent;
        errdefer if (config.userAgentSuffix() != null) allocator.free(user_agent);

        const user_agent_header = try std.fmt.allocPrintSentinel(allocator, "User-Agent: {s}", .{user_agent}, 0);
        errdefer allocator.free(user_agent_header);

        const proxy_bearer_header: ?[:0]const u8 = if (config.proxyBearerToken()) |token|
            try std.fmt.allocPrintSentinel(allocator, "Proxy-Authorization: Bearer {s}", .{token}, 0)
        else
            null;

        const gpu = randomGpuProfile();

        return .{
            .user_agent = user_agent,
            .user_agent_is_allocated = config.userAgentSuffix() != null,
            .user_agent_header = user_agent_header,
            .sec_ch_ua_header = profile.sec_ch_ua_header,
            .sec_ch_ua_mobile_header = profile.sec_ch_ua_mobile_header,
            .sec_ch_ua_platform_header = profile.sec_ch_ua_platform_header,
            .accept_language_header = profile.accept_language_header,
            .navigator_platform = profile.navigator_platform,
            .navigator_vendor = profile.navigator_vendor,
            .navigator_app_version = profile.navigator_app_version,
            .cdp_product = profile.cdp_product,
            .cdp_user_agent = profile.cdp_user_agent,
            .gpu_vendor = gpu.vendor,
            .gpu_renderer = gpu.renderer,
            .proxy_bearer_header = proxy_bearer_header,
        };
    }

    pub fn deinit(self: *const HttpHeaders, allocator: Allocator) void {
        if (self.proxy_bearer_header) |hdr| {
            allocator.free(hdr);
        }
        allocator.free(self.user_agent_header);
        if (self.user_agent_is_allocated) {
            allocator.free(self.user_agent);
        }
    }
};

pub fn printUsageAndExit(self: *const Config, success: bool) void {
    //                                                                     MAX_HELP_LEN|
    const common_options =
        \\
        \\--insecure_disable_tls_host_verification
        \\                Disables host verification on all HTTP requests. This is an
        \\                advanced option which should only be set if you understand
        \\                and accept the risk of disabling host verification.
        \\
        \\--obey_robots
        \\                Fetches and obeys the robots.txt (if available) of the web pages
        \\                we make requests towards.
        \\                Defaults to false.
        \\
        \\--http_proxy    The HTTP proxy to use for all HTTP requests.
        \\                A username:password can be included for basic authentication.
        \\                Defaults to none.
        \\
        \\--proxy_bearer_token
        \\                The <token> to send for bearer authentication with the proxy
        \\                Proxy-Authorization: Bearer <token>
        \\
        \\--http_max_concurrent
        \\                The maximum number of concurrent HTTP requests.
        \\                Defaults to 10.
        \\
        \\--http_max_host_open
        \\                The maximum number of open connection to a given host:port.
        \\                Defaults to 4.
        \\
        \\--http_connect_timeout
        \\                The time, in milliseconds, for establishing an HTTP connection
        \\                before timing out. 0 means it never times out.
        \\                Defaults to 0.
        \\
        \\--http_timeout
        \\                The maximum time, in milliseconds, the transfer is allowed
        \\                to complete. 0 means it never times out.
        \\                Defaults to 10000.
        \\
        \\--http_max_response_size
        \\                Limits the acceptable response size for any request
        \\                (e.g. XHR, fetch, script loading, ...).
        \\                Defaults to no limit.
        \\
        \\--log_level     The log level: debug, info, warn, error or fatal.
        \\                Defaults to
    ++ (if (builtin.mode == .Debug) " info." else "warn.") ++
        \\
        \\
        \\--log_format    The log format: pretty or logfmt.
        \\                Defaults to
    ++ (if (builtin.mode == .Debug) " pretty." else " logfmt.") ++
        \\
        \\
        \\--log_filter_scopes
        \\                Filter out too verbose logs per scope:
        \\                http, unknown_prop, event, ...
        \\
        \\--user_agent_suffix
        \\                Suffix to append to the Lightpanda/X.Y User-Agent
        \\
        \\--browser       Browser fingerprint used by curl-impersonate.
        \\                Supported: chrome99,chrome100,chrome101,chrome104,
        \\                chrome107,chrome110,chrome116,chrome99_android,
        \\                edge99,edge101,safari15_3,safari15_5.
        \\                If omitted, a random chrome/edge fingerprint is used.
        \\
    ;

    //                                                                     MAX_HELP_LEN|
    const usage =
        \\usage: {s} command [options] [URL]
        \\
        \\Command can be either 'fetch', 'serve' or 'help'
        \\
        \\fetch command
        \\Fetches the specified URL
        \\Example: {s} fetch --dump https://lightpanda.io/
        \\
        \\Options:
        \\--dump          Dumps document to stdout.
        \\                Defaults to false.
        \\
        \\--strip_mode    Comma separated list of tag groups to remove from dump
        \\                the dump. e.g. --strip_mode js,css
        \\                  - "js" script and link[as=script, rel=preload]
        \\                  - "ui" includes img, picture, video, css and svg
        \\                  - "css" includes style and link[rel=stylesheet]
        \\                  - "full" includes js, ui and css
        \\
        \\--with_base     Add a <base> tag in dump. Defaults to false.
        \\
    ++ common_options ++
        \\
        \\serve command
        \\Starts a websocket CDP server
        \\Example: {s} serve --host 127.0.0.1 --port 9222
        \\
        \\Options:
        \\--host          Host of the CDP server
        \\                Defaults to "127.0.0.1"
        \\
        \\--port          Port of the CDP server
        \\                Defaults to 9222
        \\
        \\--timeout       Inactivity timeout in seconds before disconnecting clients
        \\                Defaults to 10 (seconds). Limited to 604800 (1 week).
        \\
        \\--max_connections
        \\                Maximum number of simultaneous CDP connections.
        \\                Defaults to 16.
        \\
        \\--max_tabs      Maximum number of tabs per CDP connection.
        \\                Defaults to 8.
        \\
        \\--max_tab_memory
        \\                Maximum memory per tab in bytes.
        \\                Defaults to 536870912 (512 MB).
        \\
        \\--max_pending_connections
        \\                Maximum pending connections in the accept queue.
        \\                Defaults to 128.
        \\
    ++ common_options ++
        \\
        \\version command
        \\Displays the version of {s}
        \\
        \\help command
        \\Displays this message
        \\
    ;
    std.debug.print(usage, .{ self.exec_name, self.exec_name, self.exec_name, self.exec_name });
    if (success) {
        return std.process.cleanExit();
    }
    std.process.exit(1);
}

pub fn parseArgs(allocator: Allocator) !Config {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    const exec_name = try allocator.dupe(u8, std.fs.path.basename(args.next().?));

    const mode_string = args.next() orelse "";
    const run_mode = std.meta.stringToEnum(RunMode, mode_string) orelse blk: {
        const inferred_mode = inferMode(mode_string) orelse
            return init(allocator, exec_name, .{ .help = false });
        // "command" wasn't a command but an option. We can't reset args, but
        // we can create a new one. Not great, but this fallback is temporary
        // as we transition to this command mode approach.
        args.deinit();

        args = try std.process.argsWithAllocator(allocator);
        // skip the exec_name
        _ = args.skip();

        break :blk inferred_mode;
    };

    const mode: Mode = switch (run_mode) {
        .help => .{ .help = true },
        .serve => .{ .serve = parseServeArgs(allocator, &args) catch
            return init(allocator, exec_name, .{ .help = false }) },
        .fetch => .{ .fetch = parseFetchArgs(allocator, &args) catch
            return init(allocator, exec_name, .{ .help = false }) },
        .version => .{ .version = {} },
    };
    return init(allocator, exec_name, mode);
}

fn inferMode(opt: []const u8) ?RunMode {
    if (opt.len == 0) {
        return .serve;
    }

    if (std.mem.startsWith(u8, opt, "--") == false) {
        return .fetch;
    }

    if (std.mem.eql(u8, opt, "--dump")) {
        return .fetch;
    }

    if (std.mem.eql(u8, opt, "--noscript")) {
        return .fetch;
    }

    if (std.mem.eql(u8, opt, "--strip_mode")) {
        return .fetch;
    }

    if (std.mem.eql(u8, opt, "--with_base")) {
        return .fetch;
    }

    if (std.mem.eql(u8, opt, "--host")) {
        return .serve;
    }

    if (std.mem.eql(u8, opt, "--port")) {
        return .serve;
    }

    if (std.mem.eql(u8, opt, "--timeout")) {
        return .serve;
    }

    return null;
}

fn parseServeArgs(
    allocator: Allocator,
    args: *std.process.ArgIterator,
) !Serve {
    var serve: Serve = .{};

    while (args.next()) |opt| {
        if (std.mem.eql(u8, "--host", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--host" });
                return error.InvalidArgument;
            };
            serve.host = try allocator.dupe(u8, str);
            continue;
        }

        if (std.mem.eql(u8, "--port", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--port" });
                return error.InvalidArgument;
            };

            serve.port = std.fmt.parseInt(u16, str, 10) catch |err| {
                log.fatal(.app, "invalid argument value", .{ .arg = "--port", .err = err });
                return error.InvalidArgument;
            };
            continue;
        }

        if (std.mem.eql(u8, "--timeout", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--timeout" });
                return error.InvalidArgument;
            };

            serve.timeout = std.fmt.parseInt(u31, str, 10) catch |err| {
                log.fatal(.app, "invalid argument value", .{ .arg = "--timeout", .err = err });
                return error.InvalidArgument;
            };
            continue;
        }

        if (std.mem.eql(u8, "--max_connections", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--max_connections" });
                return error.InvalidArgument;
            };

            serve.max_connections = std.fmt.parseInt(u16, str, 10) catch |err| {
                log.fatal(.app, "invalid argument value", .{ .arg = "--max_connections", .err = err });
                return error.InvalidArgument;
            };
            continue;
        }

        if (std.mem.eql(u8, "--max_tabs", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--max_tabs" });
                return error.InvalidArgument;
            };

            serve.max_tabs_per_connection = std.fmt.parseInt(u16, str, 10) catch |err| {
                log.fatal(.app, "invalid argument value", .{ .arg = "--max_tabs", .err = err });
                return error.InvalidArgument;
            };
            continue;
        }

        if (std.mem.eql(u8, "--max_tab_memory", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--max_tab_memory" });
                return error.InvalidArgument;
            };

            serve.max_memory_per_tab = std.fmt.parseInt(u64, str, 10) catch |err| {
                log.fatal(.app, "invalid argument value", .{ .arg = "--max_tab_memory", .err = err });
                return error.InvalidArgument;
            };
            continue;
        }

        if (std.mem.eql(u8, "--max_pending_connections", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--max_pending_connections" });
                return error.InvalidArgument;
            };

            serve.max_pending_connections = std.fmt.parseInt(u16, str, 10) catch |err| {
                log.fatal(.app, "invalid argument value", .{ .arg = "--max_pending_connections", .err = err });
                return error.InvalidArgument;
            };
            continue;
        }

        if (try parseCommonArg(allocator, opt, args, &serve.common)) {
            continue;
        }

        log.fatal(.app, "unknown argument", .{ .mode = "serve", .arg = opt });
        return error.UnkownOption;
    }

    return serve;
}

fn parseFetchArgs(
    allocator: Allocator,
    args: *std.process.ArgIterator,
) !Fetch {
    var fetch_dump: bool = false;
    var withbase: bool = false;
    var url: ?[:0]const u8 = null;
    var common: Common = .{};
    var strip: dump.Opts.Strip = .{};

    while (args.next()) |opt| {
        if (std.mem.eql(u8, "--dump", opt)) {
            fetch_dump = true;
            continue;
        }

        if (std.mem.eql(u8, "--noscript", opt)) {
            log.warn(.app, "deprecation warning", .{
                .feature = "--noscript argument",
                .hint = "use '--strip_mode js' instead",
            });
            strip.js = true;
            continue;
        }

        if (std.mem.eql(u8, "--with_base", opt)) {
            withbase = true;
            continue;
        }

        if (std.mem.eql(u8, "--strip_mode", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--strip_mode" });
                return error.InvalidArgument;
            };

            var it = std.mem.splitScalar(u8, str, ',');
            while (it.next()) |part| {
                const trimmed = std.mem.trim(u8, part, &std.ascii.whitespace);
                if (std.mem.eql(u8, trimmed, "js")) {
                    strip.js = true;
                } else if (std.mem.eql(u8, trimmed, "ui")) {
                    strip.ui = true;
                } else if (std.mem.eql(u8, trimmed, "css")) {
                    strip.css = true;
                } else if (std.mem.eql(u8, trimmed, "full")) {
                    strip.js = true;
                    strip.ui = true;
                    strip.css = true;
                } else {
                    log.fatal(.app, "invalid option choice", .{ .arg = "--strip_mode", .value = trimmed });
                }
            }
            continue;
        }

        if (try parseCommonArg(allocator, opt, args, &common)) {
            continue;
        }

        if (std.mem.startsWith(u8, opt, "--")) {
            log.fatal(.app, "unknown argument", .{ .mode = "fetch", .arg = opt });
            return error.UnkownOption;
        }

        if (url != null) {
            log.fatal(.app, "duplicate fetch url", .{ .help = "only 1 URL can be specified" });
            return error.TooManyURLs;
        }
        url = try allocator.dupeZ(u8, opt);
    }

    if (url == null) {
        log.fatal(.app, "missing fetch url", .{ .help = "URL to fetch must be provided" });
        return error.MissingURL;
    }

    return .{
        .url = url.?,
        .dump = fetch_dump,
        .strip = strip,
        .common = common,
        .withbase = withbase,
    };
}

fn parseCommonArg(
    allocator: Allocator,
    opt: []const u8,
    args: *std.process.ArgIterator,
    common: *Common,
) !bool {
    if (std.mem.eql(u8, "--insecure_disable_tls_host_verification", opt)) {
        common.tls_verify_host = false;
        return true;
    }

    if (std.mem.eql(u8, "--obey_robots", opt)) {
        common.obey_robots = true;
        return true;
    }

    if (std.mem.eql(u8, "--http_proxy", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--http_proxy" });
            return error.InvalidArgument;
        };
        common.http_proxy = try allocator.dupeZ(u8, str);
        return true;
    }

    if (std.mem.eql(u8, "--proxy_bearer_token", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--proxy_bearer_token" });
            return error.InvalidArgument;
        };
        common.proxy_bearer_token = try allocator.dupeZ(u8, str);
        return true;
    }

    if (std.mem.eql(u8, "--http_max_concurrent", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--http_max_concurrent" });
            return error.InvalidArgument;
        };

        common.http_max_concurrent = std.fmt.parseInt(u8, str, 10) catch |err| {
            log.fatal(.app, "invalid argument value", .{ .arg = "--http_max_concurrent", .err = err });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--http_max_host_open", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--http_max_host_open" });
            return error.InvalidArgument;
        };

        common.http_max_host_open = std.fmt.parseInt(u8, str, 10) catch |err| {
            log.fatal(.app, "invalid argument value", .{ .arg = "--http_max_host_open", .err = err });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--http_connect_timeout", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--http_connect_timeout" });
            return error.InvalidArgument;
        };

        common.http_connect_timeout = std.fmt.parseInt(u31, str, 10) catch |err| {
            log.fatal(.app, "invalid argument value", .{ .arg = "--http_connect_timeout", .err = err });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--http_timeout", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--http_timeout" });
            return error.InvalidArgument;
        };

        common.http_timeout = std.fmt.parseInt(u31, str, 10) catch |err| {
            log.fatal(.app, "invalid argument value", .{ .arg = "--http_timeout", .err = err });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--http_max_response_size", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--http_max_response_size" });
            return error.InvalidArgument;
        };

        common.http_max_response_size = std.fmt.parseInt(usize, str, 10) catch |err| {
            log.fatal(.app, "invalid argument value", .{ .arg = "--http_max_response_size", .err = err });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--log_level", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--log_level" });
            return error.InvalidArgument;
        };

        common.log_level = std.meta.stringToEnum(log.Level, str) orelse blk: {
            if (std.mem.eql(u8, str, "error")) {
                break :blk .err;
            }
            log.fatal(.app, "invalid option choice", .{ .arg = "--log_level", .value = str });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--log_format", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--log_format" });
            return error.InvalidArgument;
        };

        common.log_format = std.meta.stringToEnum(log.Format, str) orelse {
            log.fatal(.app, "invalid option choice", .{ .arg = "--log_format", .value = str });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--log_filter_scopes", opt)) {
        if (builtin.mode != .Debug) {
            log.fatal(.app, "experimental", .{ .help = "log scope filtering is only available in debug builds" });
            return false;
        }

        const str = args.next() orelse {
            // disables the default filters
            common.log_filter_scopes = &.{};
            return true;
        };

        var arr: std.ArrayList(log.Scope) = .empty;

        var it = std.mem.splitScalar(u8, str, ',');
        while (it.next()) |part| {
            try arr.append(allocator, std.meta.stringToEnum(log.Scope, part) orelse {
                log.fatal(.app, "invalid option choice", .{ .arg = "--log_filter_scopes", .value = part });
                return false;
            });
        }
        common.log_filter_scopes = arr.items;
        return true;
    }

    if (std.mem.eql(u8, "--user_agent_suffix", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--user_agent_suffix" });
            return error.InvalidArgument;
        };
        for (str) |c| {
            if (!std.ascii.isPrint(c)) {
                log.fatal(.app, "not printable character", .{ .arg = "--user_agent_suffix" });
                return error.InvalidArgument;
            }
        }
        common.user_agent_suffix = try allocator.dupe(u8, str);
        return true;
    }

    if (std.mem.eql(u8, "--browser", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--browser" });
            return error.InvalidArgument;
        };

        if (!isSupportedBrowserFingerprint(str)) {
            log.fatal(.app, "invalid option choice", .{ .arg = "--browser", .value = str });
            return error.InvalidArgument;
        }

        common.browser = try allocator.dupeZ(u8, str);
        return true;
    }

    return false;
}

test "config: default browser fingerprint remains stable per process config" {
    const allocator = std.testing.allocator;

    var config = try Config.init(allocator, "test", .{ .serve = .{} });
    defer config.deinit(allocator);

    const selected = config.browserFingerprint();
    try std.testing.expect(isSupportedBrowserFingerprint(selected));

    for (0..32) |_| {
        try std.testing.expectEqualStrings(selected, config.browserFingerprint());
    }
}

test "config: explicit browser fingerprint overrides default" {
    const allocator = std.testing.allocator;

    var config = try Config.init(allocator, "test", .{ .serve = .{ .common = .{ .browser = "chrome116" } } });
    defer config.deinit(allocator);

    try std.testing.expectEqualStrings("chrome116", config.browserFingerprint());
    try std.testing.expectEqualStrings("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.180 Safari/537.36", config.browserProfile().user_agent);
}
