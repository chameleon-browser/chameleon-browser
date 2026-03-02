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

const js = @import("../../../js/js.zig");
const Page = @import("../../../Page.zig");
const Window = @import("../../Window.zig");
const VisualViewport = @import("../../VisualViewport.zig");
const Document = @import("../../Document.zig");
const HTMLDocument = @import("../../HTMLDocument.zig");
const DocumentType = @import("../../DocumentType.zig");
const Location = @import("../../Location.zig");
const Navigator = @import("../../Navigator.zig");
const Chrome = @import("../../Chrome.zig");
const EventTarget = @import("../../EventTarget.zig");
const Node = @import("../../Node.zig");
const Element = @import("../../Element.zig");
const HtmlElement = @import("../Html.zig");

pub fn registerTypes() []const type {
    return &.{ IFrame, ContentWindow };
}

const IFrame = @This();
_proto: *HtmlElement,
_content_window: ?*ContentWindow = null,

pub fn asElement(self: *IFrame) *Element {
    return self._proto._proto;
}
pub fn asConstElement(self: *const IFrame) *const Element {
    return self._proto._proto;
}
pub fn asNode(self: *IFrame) *Node {
    return self.asElement().asNode();
}

pub fn getContentWindow(self: *IFrame, page: *Page) !*ContentWindow {
    if (self._content_window) |window| {
        return window;
    }

    const content_window = try page._factory.eventTarget(ContentWindow{
        ._proto = undefined,
        ._window = page.window,
        ._frame_element = self,
    });
    self._content_window = content_window;
    return content_window;
}

pub fn getContentDocument(self: *IFrame, page: *Page) !*Document {
    const cw = try self.getContentWindow(page);
    return cw.getOrCreateDocument(page);
}

pub fn getSrcdoc(self: *const IFrame) ?[]const u8 {
    return self.asConstElement().getAttributeSafe(comptime .wrap("srcdoc"));
}

pub fn setSrcdoc(self: *IFrame, value: []const u8, page: *Page) !void {
    try self.asElement().setAttributeSafe(comptime .wrap("srcdoc"), .wrap(value), page);
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(IFrame);

    pub const Meta = struct {
        pub const name = "HTMLIFrameElement";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const contentWindow = bridge.accessor(IFrame.getContentWindow, null, .{});
    pub const contentDocument = bridge.accessor(IFrame.getContentDocument, null, .{});
    pub const srcdoc = bridge.accessor(IFrame.getSrcdoc, IFrame.setSrcdoc, .{});
};

pub const ContentWindow = struct {
    _proto: *EventTarget,
    _window: *Window,
    _frame_element: *IFrame,
    _content_document: ?*Document = null,
    _navigator: Navigator = .init,
    _chrome: Chrome = .init,

    pub fn asEventTarget(self: *ContentWindow) *EventTarget {
        return self._proto;
    }

    pub fn getSelf(self: *ContentWindow) *ContentWindow {
        return self;
    }

    pub fn getWindow(self: *ContentWindow) *ContentWindow {
        return self;
    }

    pub fn getTop(self: *ContentWindow) *Window {
        return self._window;
    }

    pub fn getParent(self: *ContentWindow) *Window {
        return self._window;
    }

    pub fn getDocument(self: *ContentWindow, page: *Page) !*Document {
        return self.getOrCreateDocument(page);
    }

    /// Lazily create the iframe's inner Document (about:blank).
    /// Follows the same pattern as DOMImplementation.createHTMLDocument.
    pub fn getOrCreateDocument(self: *ContentWindow, page: *Page) !*Document {
        if (self._content_document) |doc| {
            return doc;
        }

        // Create a standalone HTMLDocument for this iframe's browsing context.
        const html_doc = try page._factory.document(HTMLDocument{
            ._proto = undefined,
        });
        const document = html_doc.asDocument();
        document._ready_state = .complete;

        // Build the minimal document structure: <!DOCTYPE html><html><head></head><body></body></html>
        {
            const doctype = try page._factory.node(DocumentType{
                ._proto = undefined,
                ._name = "html",
                ._public_id = "",
                ._system_id = "",
            });
            _ = try document.asNode().appendChild(doctype.asNode(), page);
        }

        const html_node = try page.createElementNS(.html, "html", null);
        _ = try document.asNode().appendChild(html_node, page);

        const head_node = try page.createElementNS(.html, "head", null);
        _ = try html_node.appendChild(head_node, page);

        const body_node = try page.createElementNS(.html, "body", null);
        _ = try html_node.appendChild(body_node, page);

        self._content_document = document;
        return document;
    }

    pub fn getLocation(self: *ContentWindow) *Location {
        return self._window.getLocation();
    }

    pub fn getFrameElement(self: *ContentWindow) *IFrame {
        return self._frame_element;
    }

    pub fn getFrames(self: *ContentWindow) *ContentWindow {
        return self;
    }

    pub fn getVisualViewport(self: *ContentWindow) *VisualViewport {
        return self._window.getVisualViewport();
    }

    pub fn getOnPopState(self: *ContentWindow) ?js.Function.Global {
        return self._window.getOnPopState();
    }

    pub fn btoa(self: *ContentWindow, input: []const u8, page: *Page) ![]const u8 {
        return self._window.btoa(input, page);
    }

    pub fn atob(self: *ContentWindow, input: []const u8, page: *Page) ![]const u8 {
        return self._window.atob(input, page);
    }

    pub fn prompt(self: *const ContentWindow, message: ?js.Value, default_value: ?js.Value) ?[]const u8 {
        return self._window.prompt(message, default_value);
    }

    pub fn scrollTo(_: *ContentWindow, _: js.Value, _: ?js.Value, _: *Page) void {}

    pub fn close(self: *const ContentWindow) void {
        self._window.close();
    }

    pub fn focus(self: *const ContentWindow) void {
        self._window.focus();
    }

    pub fn blur(self: *const ContentWindow) void {
        self._window.blur();
    }

    pub fn rtcPeerConnection(self: *const ContentWindow, config: ?js.Value) void {
        self._window.rtcPeerConnection(config);
    }

    pub fn getNavigator(self: *ContentWindow) *Navigator {
        return &self._navigator;
    }

    pub fn getChrome(self: *ContentWindow) *Chrome {
        return &self._chrome;
    }

    pub fn setTimeout(self: *ContentWindow, cb: js.Value, delay_ms: ?u32, params: []js.Value.Temp, page: *Page) !u32 {
        return self._window.setTimeout(cb, delay_ms, params, page);
    }

    pub fn clearTimeout(self: *ContentWindow, id: u32) void {
        return self._window.clearTimeout(id);
    }

    pub fn setInterval(self: *ContentWindow, cb: js.Value, delay_ms: ?u32, params: []js.Value.Temp, page: *Page) !u32 {
        return self._window.setInterval(cb, delay_ms, params, page);
    }

    pub fn clearInterval(self: *ContentWindow, id: u32) void {
        return self._window.clearInterval(id);
    }

    pub const JsApi = struct {
        pub const bridge = js.Bridge(ContentWindow);

        pub const Meta = struct {
            pub const name = "Window";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const self = bridge.accessor(ContentWindow.getSelf, null, .{});
        pub const window = bridge.accessor(ContentWindow.getWindow, null, .{});
        pub const top = bridge.accessor(ContentWindow.getTop, null, .{});
        pub const parent = bridge.accessor(ContentWindow.getParent, null, .{});
        pub const document = bridge.accessor(ContentWindow.getDocument, null, .{});
        pub const location = bridge.accessor(ContentWindow.getLocation, null, .{});
        pub const frameElement = bridge.accessor(ContentWindow.getFrameElement, null, .{});
        pub const frames = bridge.accessor(ContentWindow.getFrames, null, .{});
        pub const visualViewport = bridge.accessor(ContentWindow.getVisualViewport, null, .{});
        pub const navigator = bridge.accessor(ContentWindow.getNavigator, null, .{});
        pub const chrome = bridge.accessor(ContentWindow.getChrome, null, .{});
        pub const onpopstate = bridge.accessor(ContentWindow.getOnPopState, null, .{});
        pub const setTimeout = bridge.function(ContentWindow.setTimeout, .{});
        pub const clearTimeout = bridge.function(ContentWindow.clearTimeout, .{});
        pub const setInterval = bridge.function(ContentWindow.setInterval, .{});
        pub const clearInterval = bridge.function(ContentWindow.clearInterval, .{});
        pub const btoa = bridge.function(ContentWindow.btoa, .{});
        pub const atob = bridge.function(ContentWindow.atob, .{});
        pub const prompt = bridge.function(ContentWindow.prompt, .{});
        pub const close = bridge.function(ContentWindow.close, .{});
        pub const focus = bridge.function(ContentWindow.focus, .{});
        pub const blur = bridge.function(ContentWindow.blur, .{});
        pub const RTCPeerConnection = bridge.function(ContentWindow.rtcPeerConnection, .{});
        pub const scrollTo = bridge.function(ContentWindow.scrollTo, .{});
        pub const scroll = bridge.function(ContentWindow.scrollTo, .{});

        pub const innerWidth = bridge.property(1920, .{ .template = false });
        pub const innerHeight = bridge.property(947, .{ .template = false });
        pub const outerWidth = bridge.property(1920, .{ .template = false });
        pub const outerHeight = bridge.property(1040, .{ .template = false });
        pub const devicePixelRatio = bridge.property(1.0, .{ .template = false });
    };
};
