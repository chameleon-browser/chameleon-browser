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

const SpeechSynthesis = @This();

_pad: bool = false,

pub const init: SpeechSynthesis = .{};

const Voice = struct {
    voiceURI: []const u8,
    name: []const u8,
    lang: []const u8,
    localService: bool,
    default: bool,
};

// Realistic Chrome/Windows voice list — only the default ones that show
// before any user interaction (synchronous getVoices).
const default_voices: [5]Voice = .{
    .{ .voiceURI = "Microsoft David - English (United States)", .name = "Microsoft David - English (United States)", .lang = "en-US", .localService = true, .default = true },
    .{ .voiceURI = "Microsoft Zira - English (United States)", .name = "Microsoft Zira - English (United States)", .lang = "en-US", .localService = true, .default = false },
    .{ .voiceURI = "Microsoft Mark - English (United States)", .name = "Microsoft Mark - English (United States)", .lang = "en-US", .localService = true, .default = false },
    .{ .voiceURI = "Google US English", .name = "Google US English", .lang = "en-US", .localService = false, .default = false },
    .{ .voiceURI = "Google UK English Female", .name = "Google UK English Female", .lang = "en-GB", .localService = false, .default = false },
};

pub fn getVoices(_: *const SpeechSynthesis) []const Voice {
    return &default_voices;
}

pub fn getPending(_: *const SpeechSynthesis) bool {
    return false;
}

pub fn getPaused(_: *const SpeechSynthesis) bool {
    return false;
}

pub fn getSpeaking(_: *const SpeechSynthesis) bool {
    return false;
}

pub fn cancel(_: *const SpeechSynthesis) void {}

pub const JsApi = struct {
    pub const bridge = js.Bridge(SpeechSynthesis);

    pub const Meta = struct {
        pub const name = "SpeechSynthesis";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const getVoices = bridge.function(SpeechSynthesis.getVoices, .{});
    pub const pending = bridge.accessor(SpeechSynthesis.getPending, null, .{});
    pub const paused = bridge.accessor(SpeechSynthesis.getPaused, null, .{});
    pub const speaking = bridge.accessor(SpeechSynthesis.getSpeaking, null, .{});
    pub const cancel = bridge.function(SpeechSynthesis.cancel, .{});
    pub const onvoiceschanged = bridge.property(null, .{ .template = false });
};
