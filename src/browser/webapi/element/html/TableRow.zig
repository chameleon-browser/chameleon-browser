const js = @import("../../../js/js.zig");
const Page = @import("../../../Page.zig");
const Node = @import("../../Node.zig");
const Element = @import("../../Element.zig");
const HtmlElement = @import("../Html.zig");
const TableCell = @import("TableCell.zig");

const TableRow = @This();

_proto: *HtmlElement,

pub fn asElement(self: *TableRow) *Element {
    return self._proto._proto;
}
pub fn asNode(self: *TableRow) *Node {
    return self.asElement().asNode();
}

pub fn insertCell(self: *TableRow, index_: ?i32, page: *Page) !*TableCell {
    const element = try page.document.createElement("td", null, page);
    const cell = element.is(TableCell) orelse return error.Unexpected;

    const index = index_ orelse -1;
    if (index < 0) {
        _ = try self.asNode().appendChild(cell.asNode(), page);
        return cell;
    }

    var current: i32 = 0;
    var it = self.asNode().childrenIterator();
    while (it.next()) |child| {
        if (child.is(TableCell) == null) {
            continue;
        }

        if (current == index) {
            _ = try self.asNode().insertBefore(cell.asNode(), child, page);
            return cell;
        }

        current += 1;
    }

    _ = try self.asNode().appendChild(cell.asNode(), page);
    return cell;
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(TableRow);

    pub const Meta = struct {
        pub const name = "HTMLTableRowElement";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const insertCell = bridge.function(TableRow.insertCell, .{});
};
