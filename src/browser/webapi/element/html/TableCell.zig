const String = @import("../../../../string.zig").String;
const js = @import("../../../js/js.zig");
const Page = @import("../../../Page.zig");
const Node = @import("../../Node.zig");
const Element = @import("../../Element.zig");
const HtmlElement = @import("../Html.zig");
const std = @import("std");

const TableCell = @This();

_tag_name: String,
_tag: Element.Tag,
_proto: *HtmlElement,

pub fn asElement(self: *TableCell) *Element {
    return self._proto._proto;
}
pub fn asConstElement(self: *const TableCell) *const Element {
    return self._proto._proto;
}
pub fn asNode(self: *TableCell) *Node {
    return self.asElement().asNode();
}

pub fn getColSpan(self: *const TableCell) u32 {
    const raw = self.asConstElement().getAttributeSafe(comptime .wrap("colspan")) orelse return 1;
    const parsed = std.fmt.parseInt(u32, raw, 10) catch return 1;
    return if (parsed == 0) 1 else parsed;
}

pub fn setColSpan(self: *TableCell, col_span: u32, page: *Page) !void {
    const value = if (col_span == 0) 1 else col_span;
    const s = try std.fmt.allocPrint(page.call_arena, "{d}", .{value});
    try self.asElement().setAttributeSafe(comptime .wrap("colspan"), .wrap(s), page);
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(TableCell);

    pub const Meta = struct {
        pub const name = "HTMLTableCellElement";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const colSpan = bridge.accessor(TableCell.getColSpan, TableCell.setColSpan, .{});
};
