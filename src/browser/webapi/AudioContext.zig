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
const log = @import("../../log.zig");
const Allocator = std.mem.Allocator;

pub fn registerTypes() []const type {
    return &.{
        AudioContext,
        OfflineAudioContext,
        WebkitOfflineAudioContext,
        AudioDestinationNode,
        AudioListener,
        AnalyserNode,
        OscillatorNode,
        DynamicsCompressorNode,
        GainNode,
        BiquadFilterNode,
        AudioParam,
        AudioBuffer,
    };
}

const AudioContext = @This();

// ---------------------------------------------------------------------------
// AudioParam — stub that stores a value; factory-allocated for bridge compat
// ---------------------------------------------------------------------------
pub const AudioParam = struct {
    _value: f64,

    pub fn getValue(self: *const AudioParam) f64 {
        return self._value;
    }

    pub fn setValue(self: *AudioParam, v: f64) void {
        self._value = v;
    }

    pub fn setValueAtTime(self: *AudioParam, value: f64, _: f64) *AudioParam {
        self._value = value;
        return self;
    }

    pub fn linearRampToValueAtTime(self: *AudioParam, value: f64, _: f64) *AudioParam {
        self._value = value;
        return self;
    }

    pub fn exponentialRampToValueAtTime(self: *AudioParam, value: f64, _: f64) *AudioParam {
        self._value = value;
        return self;
    }

    pub fn setTargetAtTime(self: *AudioParam, target: f64, _: f64, _: f64) *AudioParam {
        self._value = target;
        return self;
    }

    pub fn cancelScheduledValues(self: *AudioParam, _: f64) *AudioParam {
        return self;
    }

    pub const JsApi = struct {
        pub const bridge = js.Bridge(AudioParam);

        pub const Meta = struct {
            pub const name = "AudioParam";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const value = bridge.accessor(AudioParam.getValue, AudioParam.setValue, .{});
        pub const defaultValue = bridge.property(0.0, .{ .template = false });
        pub const minValue = bridge.property(-3.4028235e+38, .{ .template = false });
        pub const maxValue = bridge.property(3.4028235e+38, .{ .template = false });
        pub const setValueAtTime = bridge.function(AudioParam.setValueAtTime, .{});
        pub const linearRampToValueAtTime = bridge.function(AudioParam.linearRampToValueAtTime, .{});
        pub const exponentialRampToValueAtTime = bridge.function(AudioParam.exponentialRampToValueAtTime, .{});
        pub const setTargetAtTime = bridge.function(AudioParam.setTargetAtTime, .{});
        pub const cancelScheduledValues = bridge.function(AudioParam.cancelScheduledValues, .{});
    };
};

/// Helper: create an AudioParam via factory
fn createParam(page: *Page, initial_value: f64) !*AudioParam {
    return page._factory.create(AudioParam{ ._value = initial_value });
}

// ---------------------------------------------------------------------------
// AudioBuffer — holds pre-generated channel data
// ---------------------------------------------------------------------------
pub const AudioBuffer = struct {
    _length: i32,
    _sample_rate: f64,
    _number_of_channels: i32,
    _channel_data: []const f32,

    pub fn getLength(self: *const AudioBuffer) i32 {
        return self._length;
    }

    pub fn getSampleRate(self: *const AudioBuffer) f64 {
        return self._sample_rate;
    }

    pub fn getNumberOfChannels(self: *const AudioBuffer) i32 {
        return self._number_of_channels;
    }

    pub fn getDuration(self: *const AudioBuffer) f64 {
        if (self._sample_rate == 0) return 0;
        return @as(f64, @floatFromInt(self._length)) / self._sample_rate;
    }

    pub fn getChannelData(self: *const AudioBuffer, _: i32) js.TypedArray(f32) {
        return .{ .values = self._channel_data };
    }

    pub fn copyFromChannel(self: *const AudioBuffer, _: i32) js.TypedArray(f32) {
        return .{ .values = self._channel_data };
    }

    pub const JsApi = struct {
        pub const bridge = js.Bridge(AudioBuffer);

        pub const Meta = struct {
            pub const name = "AudioBuffer";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const length = bridge.accessor(AudioBuffer.getLength, null, .{});
        pub const sampleRate = bridge.accessor(AudioBuffer.getSampleRate, null, .{});
        pub const numberOfChannels = bridge.accessor(AudioBuffer.getNumberOfChannels, null, .{});
        pub const duration = bridge.accessor(AudioBuffer.getDuration, null, .{});
        pub const getChannelData = bridge.function(AudioBuffer.getChannelData, .{});
        pub const copyFromChannel = bridge.function(AudioBuffer.copyFromChannel, .{});
    };
};

// ---------------------------------------------------------------------------
// OscillatorNode — factory-allocated AudioParam pointers
// ---------------------------------------------------------------------------
pub const OscillatorNode = struct {
    _frequency: *AudioParam,
    _detune: *AudioParam,

    pub fn getFrequency(self: *OscillatorNode) *AudioParam {
        return self._frequency;
    }

    pub fn getDetune(self: *OscillatorNode) *AudioParam {
        return self._detune;
    }

    pub fn connect(_: *OscillatorNode, _: js.Value) void {}
    pub fn disconnect(_: *OscillatorNode) void {}
    pub fn start(_: *OscillatorNode, _: ?f64) void {}
    pub fn stop(_: *OscillatorNode, _: ?f64) void {}

    pub const JsApi = struct {
        pub const bridge = js.Bridge(OscillatorNode);

        pub const Meta = struct {
            pub const name = "OscillatorNode";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const @"type" = bridge.property("sine", .{ .template = false });
        pub const frequency = bridge.accessor(OscillatorNode.getFrequency, null, .{});
        pub const detune = bridge.accessor(OscillatorNode.getDetune, null, .{});
        pub const connect = bridge.function(OscillatorNode.connect, .{});
        pub const disconnect = bridge.function(OscillatorNode.disconnect, .{});
        pub const start = bridge.function(OscillatorNode.start, .{});
        pub const stop = bridge.function(OscillatorNode.stop, .{});
        pub const channelCount = bridge.property(2, .{ .template = false });
        pub const channelCountMode = bridge.property("max", .{ .template = false });
        pub const channelInterpretation = bridge.property("speakers", .{ .template = false });
        pub const numberOfInputs = bridge.property(0, .{ .template = false });
        pub const numberOfOutputs = bridge.property(1, .{ .template = false });
    };
};

// ---------------------------------------------------------------------------
// DynamicsCompressorNode
// ---------------------------------------------------------------------------
pub const DynamicsCompressorNode = struct {
    _threshold: *AudioParam,
    _knee: *AudioParam,
    _ratio: *AudioParam,
    _attack: *AudioParam,
    _release: *AudioParam,

    pub fn getThreshold(self: *DynamicsCompressorNode) *AudioParam {
        return self._threshold;
    }
    pub fn getKnee(self: *DynamicsCompressorNode) *AudioParam {
        return self._knee;
    }
    pub fn getRatio(self: *DynamicsCompressorNode) *AudioParam {
        return self._ratio;
    }
    pub fn getAttack(self: *DynamicsCompressorNode) *AudioParam {
        return self._attack;
    }
    pub fn getRelease(self: *DynamicsCompressorNode) *AudioParam {
        return self._release;
    }

    pub fn connect(_: *DynamicsCompressorNode, _: js.Value) void {}
    pub fn disconnect(_: *DynamicsCompressorNode) void {}

    pub const JsApi = struct {
        pub const bridge = js.Bridge(DynamicsCompressorNode);

        pub const Meta = struct {
            pub const name = "DynamicsCompressorNode";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const threshold = bridge.accessor(DynamicsCompressorNode.getThreshold, null, .{});
        pub const knee = bridge.accessor(DynamicsCompressorNode.getKnee, null, .{});
        pub const ratio = bridge.accessor(DynamicsCompressorNode.getRatio, null, .{});
        pub const attack = bridge.accessor(DynamicsCompressorNode.getAttack, null, .{});
        pub const release = bridge.accessor(DynamicsCompressorNode.getRelease, null, .{});
        pub const reduction = bridge.property(0.0, .{ .template = false });
        pub const connect = bridge.function(DynamicsCompressorNode.connect, .{});
        pub const disconnect = bridge.function(DynamicsCompressorNode.disconnect, .{});
        pub const channelCount = bridge.property(2, .{ .template = false });
        pub const channelCountMode = bridge.property("clamped-max", .{ .template = false });
        pub const channelInterpretation = bridge.property("speakers", .{ .template = false });
        pub const numberOfInputs = bridge.property(1, .{ .template = false });
        pub const numberOfOutputs = bridge.property(1, .{ .template = false });
    };
};

// ---------------------------------------------------------------------------
// GainNode
// ---------------------------------------------------------------------------
pub const GainNode = struct {
    _gain: *AudioParam,

    pub fn getGain(self: *GainNode) *AudioParam {
        return self._gain;
    }

    pub fn connect(_: *GainNode, _: js.Value) void {}
    pub fn disconnect(_: *GainNode) void {}

    pub const JsApi = struct {
        pub const bridge = js.Bridge(GainNode);

        pub const Meta = struct {
            pub const name = "GainNode";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const gain = bridge.accessor(GainNode.getGain, null, .{});
        pub const connect = bridge.function(GainNode.connect, .{});
        pub const disconnect = bridge.function(GainNode.disconnect, .{});
        pub const channelCount = bridge.property(2, .{ .template = false });
        pub const channelCountMode = bridge.property("max", .{ .template = false });
        pub const channelInterpretation = bridge.property("speakers", .{ .template = false });
        pub const numberOfInputs = bridge.property(1, .{ .template = false });
        pub const numberOfOutputs = bridge.property(1, .{ .template = false });
    };
};

// ---------------------------------------------------------------------------
// BiquadFilterNode
// ---------------------------------------------------------------------------
pub const BiquadFilterNode = struct {
    _frequency: *AudioParam,
    _detune: *AudioParam,
    _q: *AudioParam,
    _gain_param: *AudioParam,

    pub fn getFrequency(self: *BiquadFilterNode) *AudioParam {
        return self._frequency;
    }
    pub fn getDetune(self: *BiquadFilterNode) *AudioParam {
        return self._detune;
    }
    pub fn getQ(self: *BiquadFilterNode) *AudioParam {
        return self._q;
    }
    pub fn getGain(self: *BiquadFilterNode) *AudioParam {
        return self._gain_param;
    }

    pub fn connect(_: *BiquadFilterNode, _: js.Value) void {}
    pub fn disconnect(_: *BiquadFilterNode) void {}

    pub const JsApi = struct {
        pub const bridge = js.Bridge(BiquadFilterNode);

        pub const Meta = struct {
            pub const name = "BiquadFilterNode";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const @"type" = bridge.property("lowpass", .{ .template = false });
        pub const frequency = bridge.accessor(BiquadFilterNode.getFrequency, null, .{});
        pub const detune = bridge.accessor(BiquadFilterNode.getDetune, null, .{});
        pub const Q = bridge.accessor(BiquadFilterNode.getQ, null, .{});
        pub const gain = bridge.accessor(BiquadFilterNode.getGain, null, .{});
        pub const connect = bridge.function(BiquadFilterNode.connect, .{});
        pub const disconnect = bridge.function(BiquadFilterNode.disconnect, .{});
        pub const channelCount = bridge.property(2, .{ .template = false });
        pub const channelCountMode = bridge.property("max", .{ .template = false });
        pub const channelInterpretation = bridge.property("speakers", .{ .template = false });
        pub const numberOfInputs = bridge.property(1, .{ .template = false });
        pub const numberOfOutputs = bridge.property(1, .{ .template = false });
    };
};

// ---------------------------------------------------------------------------
// Deterministic audio buffer generation
// ---------------------------------------------------------------------------
fn generateAudioBuffer(allocator: std.mem.Allocator, length: usize) ![]f32 {
    const buf = try allocator.alloc(f32, length);

    // Simulate triangle oscillator at 10000 Hz through dynamics compressor
    // at 44100 Hz sample rate.
    const freq: f64 = 10000.0;
    const sample_rate: f64 = 44100.0;
    const period = sample_rate / freq;

    for (buf, 0..) |*sample, i| {
        const fi: f64 = @floatFromInt(i);

        // Triangle wave
        const phase = @mod(fi / period, 1.0);
        const triangle: f64 = if (phase < 0.5)
            4.0 * phase - 1.0
        else
            3.0 - 4.0 * phase;

        // Simple compressor simulation: soft-knee compression
        const threshold: f64 = -50.0;
        const ratio: f64 = 12.0;
        const db: f64 = 20.0 * @log10(@max(@abs(triangle), 1e-20));
        const compressed_db = if (db > threshold)
            threshold + (db - threshold) / ratio
        else
            db;
        const compressed = std.math.sign(triangle) * std.math.pow(f64, 10.0, compressed_db / 20.0);

        // Deterministic noise for unique "hardware signature"
        const noise_seed: u32 = @as(u32, @intCast(i)) *% 2654435761;
        const noise_val: f64 = @as(f64, @floatFromInt(noise_seed >> 16)) / 65536.0;
        const noise = (noise_val - 0.5) * 0.0001;

        sample.* = @floatCast(compressed + noise);
    }

    return buf;
}

// ---------------------------------------------------------------------------
// OfflineAudioContext
// ---------------------------------------------------------------------------
pub const OfflineAudioContext = struct {
    _length: i32,
    _sample_rate: f64,
    _destination: AudioDestinationNode = .init,
    _on_complete: ?js.Function.Temp = null,
    _rendered_buffer: ?*AudioBuffer = null,
    _promise_resolver: ?js.PromiseResolver.Global = null,
    _page: ?*Page = null,

    pub fn init(number_of_channels: i32, length: i32, sample_rate: f64, page: *Page) !*OfflineAudioContext {
        if (number_of_channels <= 0 or length <= 0 or sample_rate <= 0) {
            return error.InvalidArgument;
        }
        return page._factory.create(OfflineAudioContext{
            ._length = length,
            ._sample_rate = sample_rate,
        });
    }

    pub fn getLength(self: *const OfflineAudioContext) i32 {
        return self._length;
    }

    pub fn getSampleRate(self: *const OfflineAudioContext) f64 {
        return self._sample_rate;
    }

    pub fn getCurrentTime(_: *const OfflineAudioContext) f64 {
        return 0.0;
    }

    pub fn getState(_: *const OfflineAudioContext) []const u8 {
        return "suspended";
    }

    pub fn getDestination(self: *OfflineAudioContext) *AudioDestinationNode {
        return &self._destination;
    }

    pub fn getOnComplete(self: *const OfflineAudioContext) ?js.Function.Temp {
        return self._on_complete;
    }

    pub fn setOnComplete(self: *OfflineAudioContext, cb_: ?js.Function) !void {
        if (cb_) |cb| {
            self._on_complete = try cb.tempWithThis(self);
        } else {
            self._on_complete = null;
        }
    }

    pub fn createOscillator(_: *OfflineAudioContext, page: *Page) !*OscillatorNode {
        return page._factory.create(OscillatorNode{
            ._frequency = try createParam(page, 440.0),
            ._detune = try createParam(page, 0.0),
        });
    }

    pub fn createDynamicsCompressor(_: *OfflineAudioContext, page: *Page) !*DynamicsCompressorNode {
        return page._factory.create(DynamicsCompressorNode{
            ._threshold = try createParam(page, -24.0),
            ._knee = try createParam(page, 30.0),
            ._ratio = try createParam(page, 12.0),
            ._attack = try createParam(page, 0.003),
            ._release = try createParam(page, 0.25),
        });
    }

    pub fn createGain(_: *OfflineAudioContext, page: *Page) !*GainNode {
        return page._factory.create(GainNode{
            ._gain = try createParam(page, 1.0),
        });
    }

    pub fn createBiquadFilter(_: *OfflineAudioContext, page: *Page) !*BiquadFilterNode {
        return page._factory.create(BiquadFilterNode{
            ._frequency = try createParam(page, 350.0),
            ._detune = try createParam(page, 0.0),
            ._q = try createParam(page, 1.0),
            ._gain_param = try createParam(page, 0.0),
        });
    }

    pub fn createAnalyser(_: *OfflineAudioContext, page: *Page) !*AnalyserNode {
        return page._factory.create(AnalyserNode{});
    }

    pub fn startRendering(self: *OfflineAudioContext, page: *Page) !js.Promise {
        // Generate the audio buffer immediately
        const len: usize = if (self._length > 0) @intCast(self._length) else 1;
        const channel_data = generateAudioBuffer(page.arena, len) catch {
            const empty = page.arena.alloc(f32, 1) catch return error.OutOfMemory;
            empty[0] = 0.0;
            self._rendered_buffer = page._factory.create(AudioBuffer{
                ._length = 1,
                ._sample_rate = self._sample_rate,
                ._number_of_channels = 1,
                ._channel_data = empty,
            }) catch return error.OutOfMemory;
            return self.scheduleCompletion(page);
        };

        self._rendered_buffer = try page._factory.create(AudioBuffer{
            ._length = self._length,
            ._sample_rate = self._sample_rate,
            ._number_of_channels = 1,
            ._channel_data = channel_data,
        });
        return self.scheduleCompletion(page);
    }

    /// Create a pending promise and schedule a 0ms macrotask to resolve it
    /// and fire oncomplete. This allows JS to set oncomplete AFTER calling
    /// startRendering(), matching real browser async behavior.
    fn scheduleCompletion(self: *OfflineAudioContext, page: *Page) !js.Promise {
        const local = page.js.local.?;

        // Create a pending promise resolver and persist it for later
        var resolver = local.createPromiseResolver();
        self._promise_resolver = try resolver.persist();
        self._page = page;

        // Schedule completion as a 0ms macrotask (fires after current JS stack unwinds)
        const arena = try page.getArena(.{ .debug = "OfflineAudio.complete" });
        errdefer page.releaseArena(arena);

        const callback = try arena.create(RenderCompleteCallback);
        callback.* = .{
            .ctx = self,
            .page = page,
            .arena = arena,
        };
        try page.js.scheduler.add(callback, RenderCompleteCallback.run, 0, .{
            .name = "offlineAudioContext.complete",
            .low_priority = false,
            .finalizer = RenderCompleteCallback.cancelled,
        });

        return resolver.promise();
    }

    const RenderCompleteCallback = struct {
        ctx: *OfflineAudioContext,
        page: *Page,
        arena: Allocator,

        fn cancelled(raw: *anyopaque) void {
            const self: *RenderCompleteCallback = @ptrCast(@alignCast(raw));
            self.page.releaseArena(self.arena);
        }

        fn run(raw: *anyopaque) !?u32 {
            const self: *RenderCompleteCallback = @ptrCast(@alignCast(raw));
            const page = self.page;
            const ctx = self.ctx;
            defer page.releaseArena(self.arena);

            var ls: js.Local.Scope = undefined;
            page.js.localScope(&ls);
            defer ls.deinit();

            const local = &ls.local;

            // Resolve the promise with the rendered buffer
            if (ctx._promise_resolver) |*pr| {
                const resolver = pr.local(local);
                resolver.resolve("OfflineAudioContext.startRendering", ctx._rendered_buffer);
                ctx._promise_resolver = null;
            }

            // Call oncomplete callback if set: oncomplete({renderedBuffer: buffer})
            if (ctx._on_complete) |on_complete| {
                const event_obj = local.newObject();
                _ = event_obj.set("renderedBuffer", ctx._rendered_buffer, .{}) catch {};
                const func = local.toLocal(on_complete);
                func.call(void, .{event_obj.toValue()}) catch |err| {
                    log.warn(.js, "oncomplete callback error", .{ .err = err });
                };
            }

            return null;
        }
    };

    pub const JsApi = struct {
        pub const bridge = js.Bridge(OfflineAudioContext);

        pub const Meta = struct {
            pub const name = "OfflineAudioContext";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const constructor = bridge.constructor(OfflineAudioContext.init, .{});
        pub const length = bridge.accessor(OfflineAudioContext.getLength, null, .{});
        pub const sampleRate = bridge.accessor(OfflineAudioContext.getSampleRate, null, .{});
        pub const currentTime = bridge.accessor(OfflineAudioContext.getCurrentTime, null, .{});
        pub const state = bridge.accessor(OfflineAudioContext.getState, null, .{});
        pub const destination = bridge.accessor(OfflineAudioContext.getDestination, null, .{});
        pub const oncomplete = bridge.accessor(OfflineAudioContext.getOnComplete, OfflineAudioContext.setOnComplete, .{});
        pub const createOscillator = bridge.function(OfflineAudioContext.createOscillator, .{});
        pub const createDynamicsCompressor = bridge.function(OfflineAudioContext.createDynamicsCompressor, .{});
        pub const createGain = bridge.function(OfflineAudioContext.createGain, .{});
        pub const createBiquadFilter = bridge.function(OfflineAudioContext.createBiquadFilter, .{});
        pub const createAnalyser = bridge.function(OfflineAudioContext.createAnalyser, .{});
        pub const startRendering = bridge.function(OfflineAudioContext.startRendering, .{});
    };
};

// ---------------------------------------------------------------------------
// WebkitOfflineAudioContext — alias
// ---------------------------------------------------------------------------
pub const WebkitOfflineAudioContext = struct {
    _length: i32,
    _sample_rate: f64,
    _destination: AudioDestinationNode = .init,
    _on_complete: ?js.Function.Temp = null,
    _rendered_buffer: ?*AudioBuffer = null,
    _promise_resolver: ?js.PromiseResolver.Global = null,
    _page: ?*Page = null,

    pub fn init(number_of_channels: i32, length: i32, sample_rate: f64, page: *Page) !*WebkitOfflineAudioContext {
        if (number_of_channels <= 0 or length <= 0 or sample_rate <= 0) {
            return error.InvalidArgument;
        }
        return page._factory.create(WebkitOfflineAudioContext{
            ._length = length,
            ._sample_rate = sample_rate,
        });
    }

    pub fn getLength(self: *const WebkitOfflineAudioContext) i32 {
        return self._length;
    }

    pub fn getSampleRate(self: *const WebkitOfflineAudioContext) f64 {
        return self._sample_rate;
    }

    pub fn getCurrentTime(_: *const WebkitOfflineAudioContext) f64 {
        return 0.0;
    }

    pub fn getState(_: *const WebkitOfflineAudioContext) []const u8 {
        return "suspended";
    }

    pub fn getDestination(self: *WebkitOfflineAudioContext) *AudioDestinationNode {
        return &self._destination;
    }

    pub fn getOnComplete(self: *const WebkitOfflineAudioContext) ?js.Function.Temp {
        return self._on_complete;
    }

    pub fn setOnComplete(self: *WebkitOfflineAudioContext, cb_: ?js.Function) !void {
        if (cb_) |cb| {
            self._on_complete = try cb.tempWithThis(self);
        } else {
            self._on_complete = null;
        }
    }

    pub fn createOscillator(_: *WebkitOfflineAudioContext, page: *Page) !*OscillatorNode {
        return page._factory.create(OscillatorNode{
            ._frequency = try createParam(page, 440.0),
            ._detune = try createParam(page, 0.0),
        });
    }

    pub fn createDynamicsCompressor(_: *WebkitOfflineAudioContext, page: *Page) !*DynamicsCompressorNode {
        return page._factory.create(DynamicsCompressorNode{
            ._threshold = try createParam(page, -24.0),
            ._knee = try createParam(page, 30.0),
            ._ratio = try createParam(page, 12.0),
            ._attack = try createParam(page, 0.003),
            ._release = try createParam(page, 0.25),
        });
    }

    pub fn createGain(_: *WebkitOfflineAudioContext, page: *Page) !*GainNode {
        return page._factory.create(GainNode{
            ._gain = try createParam(page, 1.0),
        });
    }

    pub fn createBiquadFilter(_: *WebkitOfflineAudioContext, page: *Page) !*BiquadFilterNode {
        return page._factory.create(BiquadFilterNode{
            ._frequency = try createParam(page, 350.0),
            ._detune = try createParam(page, 0.0),
            ._q = try createParam(page, 1.0),
            ._gain_param = try createParam(page, 0.0),
        });
    }

    pub fn createAnalyser(_: *WebkitOfflineAudioContext, page: *Page) !*AnalyserNode {
        return page._factory.create(AnalyserNode{});
    }

    pub fn startRendering(self: *WebkitOfflineAudioContext, page: *Page) !js.Promise {
        // Generate the audio buffer immediately
        const len: usize = if (self._length > 0) @intCast(self._length) else 1;
        const channel_data = generateAudioBuffer(page.arena, len) catch {
            const empty = page.arena.alloc(f32, 1) catch return error.OutOfMemory;
            empty[0] = 0.0;
            self._rendered_buffer = page._factory.create(AudioBuffer{
                ._length = 1,
                ._sample_rate = self._sample_rate,
                ._number_of_channels = 1,
                ._channel_data = empty,
            }) catch return error.OutOfMemory;
            return self.scheduleCompletion(page);
        };

        self._rendered_buffer = try page._factory.create(AudioBuffer{
            ._length = self._length,
            ._sample_rate = self._sample_rate,
            ._number_of_channels = 1,
            ._channel_data = channel_data,
        });
        return self.scheduleCompletion(page);
    }

    /// Create a pending promise and schedule a 0ms macrotask to resolve it
    /// and fire oncomplete. This allows JS to set oncomplete AFTER calling
    /// startRendering(), matching real browser async behavior.
    fn scheduleCompletion(self: *WebkitOfflineAudioContext, page: *Page) !js.Promise {
        const local = page.js.local.?;

        // Create a pending promise resolver and persist it for later
        var resolver = local.createPromiseResolver();
        self._promise_resolver = try resolver.persist();
        self._page = page;

        // Schedule completion as a 0ms macrotask (fires after current JS stack unwinds)
        const arena = try page.getArena(.{ .debug = "WebkitOfflineAudio.complete" });
        errdefer page.releaseArena(arena);

        const callback = try arena.create(WebkitRenderCompleteCallback);
        callback.* = .{
            .ctx = self,
            .page = page,
            .arena = arena,
        };
        try page.js.scheduler.add(callback, WebkitRenderCompleteCallback.run, 0, .{
            .name = "webkitOfflineAudioContext.complete",
            .low_priority = false,
            .finalizer = WebkitRenderCompleteCallback.cancelled,
        });

        return resolver.promise();
    }

    const WebkitRenderCompleteCallback = struct {
        ctx: *WebkitOfflineAudioContext,
        page: *Page,
        arena: Allocator,

        fn cancelled(raw: *anyopaque) void {
            const self: *WebkitRenderCompleteCallback = @ptrCast(@alignCast(raw));
            self.page.releaseArena(self.arena);
        }

        fn run(raw: *anyopaque) !?u32 {
            const self: *WebkitRenderCompleteCallback = @ptrCast(@alignCast(raw));
            const page = self.page;
            const ctx = self.ctx;
            defer page.releaseArena(self.arena);

            var ls: js.Local.Scope = undefined;
            page.js.localScope(&ls);
            defer ls.deinit();

            const local = &ls.local;

            // Resolve the promise with the rendered buffer
            if (ctx._promise_resolver) |*pr| {
                const resolver = pr.local(local);
                resolver.resolve("WebkitOfflineAudioContext.startRendering", ctx._rendered_buffer);
                ctx._promise_resolver = null;
            }

            // Call oncomplete callback if set: oncomplete({renderedBuffer: buffer})
            if (ctx._on_complete) |on_complete| {
                const event_obj = local.newObject();
                _ = event_obj.set("renderedBuffer", ctx._rendered_buffer, .{}) catch {};
                const func = local.toLocal(on_complete);
                func.call(void, .{event_obj.toValue()}) catch |err| {
                    log.warn(.js, "oncomplete callback error", .{ .err = err });
                };
            }

            return null;
        }
    };

    pub const JsApi = struct {
        pub const bridge = js.Bridge(WebkitOfflineAudioContext);

        pub const Meta = struct {
            pub const name = "webkitOfflineAudioContext";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const constructor = bridge.constructor(WebkitOfflineAudioContext.init, .{});
        pub const length = bridge.accessor(WebkitOfflineAudioContext.getLength, null, .{});
        pub const sampleRate = bridge.accessor(WebkitOfflineAudioContext.getSampleRate, null, .{});
        pub const currentTime = bridge.accessor(WebkitOfflineAudioContext.getCurrentTime, null, .{});
        pub const state = bridge.accessor(WebkitOfflineAudioContext.getState, null, .{});
        pub const destination = bridge.accessor(WebkitOfflineAudioContext.getDestination, null, .{});
        pub const oncomplete = bridge.accessor(WebkitOfflineAudioContext.getOnComplete, WebkitOfflineAudioContext.setOnComplete, .{});
        pub const createOscillator = bridge.function(WebkitOfflineAudioContext.createOscillator, .{});
        pub const createDynamicsCompressor = bridge.function(WebkitOfflineAudioContext.createDynamicsCompressor, .{});
        pub const createGain = bridge.function(WebkitOfflineAudioContext.createGain, .{});
        pub const createBiquadFilter = bridge.function(WebkitOfflineAudioContext.createBiquadFilter, .{});
        pub const createAnalyser = bridge.function(WebkitOfflineAudioContext.createAnalyser, .{});
        pub const startRendering = bridge.function(WebkitOfflineAudioContext.startRendering, .{});
    };
};

// ---------------------------------------------------------------------------
// AudioContext (online)
// ---------------------------------------------------------------------------

_destination: AudioDestinationNode = .init,
_listener: AudioListener = .init,

pub fn init(page: *Page) !*AudioContext {
    return page._factory.create(AudioContext{});
}

pub fn getDestination(self: *AudioContext) *AudioDestinationNode {
    return &self._destination;
}

pub fn getListener(self: *AudioContext) *AudioListener {
    return &self._listener;
}

pub fn getCurrentTime(_: *const AudioContext) f64 {
    return 0.0;
}

pub fn getState(_: *const AudioContext) []const u8 {
    return "running";
}

pub fn createAnalyser(_: *AudioContext, page: *Page) !*AnalyserNode {
    return page._factory.create(AnalyserNode{});
}

pub fn createOscillator(_: *AudioContext, page: *Page) !*OscillatorNode {
    return page._factory.create(OscillatorNode{
        ._frequency = try createParam(page, 440.0),
        ._detune = try createParam(page, 0.0),
    });
}

pub fn createDynamicsCompressor(_: *AudioContext, page: *Page) !*DynamicsCompressorNode {
    return page._factory.create(DynamicsCompressorNode{
        ._threshold = try createParam(page, -24.0),
        ._knee = try createParam(page, 30.0),
        ._ratio = try createParam(page, 12.0),
        ._attack = try createParam(page, 0.003),
        ._release = try createParam(page, 0.25),
    });
}

pub fn createGain(_: *AudioContext, page: *Page) !*GainNode {
    return page._factory.create(GainNode{
        ._gain = try createParam(page, 1.0),
    });
}

pub fn createBiquadFilter(_: *AudioContext, page: *Page) !*BiquadFilterNode {
    return page._factory.create(BiquadFilterNode{
        ._frequency = try createParam(page, 350.0),
        ._detune = try createParam(page, 0.0),
        ._q = try createParam(page, 1.0),
        ._gain_param = try createParam(page, 0.0),
    });
}

// ---------------------------------------------------------------------------
// AudioDestinationNode
// ---------------------------------------------------------------------------
pub const AudioDestinationNode = struct {
    _pad: bool = false,

    pub const init: AudioDestinationNode = .{};

    pub const JsApi = struct {
        pub const bridge = js.Bridge(AudioDestinationNode);

        pub const Meta = struct {
            pub const name = "AudioDestinationNode";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const maxChannelCount = bridge.property(2, .{ .template = false });
        pub const channelCount = bridge.property(2, .{ .template = false });
        pub const channelCountMode = bridge.property("explicit", .{ .template = false });
        pub const channelInterpretation = bridge.property("speakers", .{ .template = false });
        pub const numberOfInputs = bridge.property(1, .{ .template = false });
        pub const numberOfOutputs = bridge.property(0, .{ .template = false });
    };
};

// ---------------------------------------------------------------------------
// AudioListener
// ---------------------------------------------------------------------------
pub const AudioListener = struct {
    _pad: bool = false,

    pub const init: AudioListener = .{};

    pub const JsApi = struct {
        pub const bridge = js.Bridge(AudioListener);

        pub const Meta = struct {
            pub const name = "AudioListener";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const dopplerFactor = bridge.property(1.0, .{ .template = false });
        pub const speedOfSound = bridge.property(343.3, .{ .template = false });
    };
};

// ---------------------------------------------------------------------------
// AnalyserNode
// ---------------------------------------------------------------------------
pub const AnalyserNode = struct {
    _pad: bool = false,

    pub fn connect(_: *AnalyserNode, _: js.Value) void {}
    pub fn disconnect(_: *AnalyserNode) void {}

    pub const JsApi = struct {
        pub const bridge = js.Bridge(AnalyserNode);

        pub const Meta = struct {
            pub const name = "AnalyserNode";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const fftSize = bridge.property(2048, .{ .template = false });
        pub const frequencyBinCount = bridge.property(1024, .{ .template = false });
        pub const maxDecibels = bridge.property(-30.0, .{ .template = false });
        pub const minDecibels = bridge.property(-100.0, .{ .template = false });
        pub const smoothingTimeConstant = bridge.property(0.8, .{ .template = false });
        pub const connect = bridge.function(AnalyserNode.connect, .{});
        pub const disconnect = bridge.function(AnalyserNode.disconnect, .{});
        pub const channelCount = bridge.property(2, .{ .template = false });
        pub const channelCountMode = bridge.property("max", .{ .template = false });
        pub const channelInterpretation = bridge.property("speakers", .{ .template = false });
        pub const numberOfInputs = bridge.property(1, .{ .template = false });
        pub const numberOfOutputs = bridge.property(1, .{ .template = false });
    };
};

// ---------------------------------------------------------------------------
// AudioContext JsApi
// ---------------------------------------------------------------------------
pub const JsApi = struct {
    pub const bridge = js.Bridge(AudioContext);

    pub const Meta = struct {
        pub const name = "AudioContext";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const constructor = bridge.constructor(AudioContext.init, .{});
    pub const destination = bridge.accessor(AudioContext.getDestination, null, .{});
    pub const listener = bridge.accessor(AudioContext.getListener, null, .{});
    pub const currentTime = bridge.accessor(AudioContext.getCurrentTime, null, .{});
    pub const state = bridge.accessor(AudioContext.getState, null, .{});
    pub const createAnalyser = bridge.function(AudioContext.createAnalyser, .{});
    pub const createOscillator = bridge.function(AudioContext.createOscillator, .{});
    pub const createDynamicsCompressor = bridge.function(AudioContext.createDynamicsCompressor, .{});
    pub const createGain = bridge.function(AudioContext.createGain, .{});
    pub const createBiquadFilter = bridge.function(AudioContext.createBiquadFilter, .{});
    pub const sampleRate = bridge.property(44100.0, .{ .template = false });
    pub const baseLatency = bridge.property(0.005333333333333333, .{ .template = false });
    pub const outputLatency = bridge.property(0.0, .{ .template = false });
};
