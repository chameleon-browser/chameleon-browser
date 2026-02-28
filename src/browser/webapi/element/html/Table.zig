const js = @import("../../../js/js.zig");
const Page = @import("../../../Page.zig");
const Node = @import("../../Node.zig");
const Element = @import("../../Element.zig");
const HtmlElement = @import("../Html.zig");
const TableRow = @import("TableRow.zig");

const Table = @This();

_proto: *HtmlElement,

pub fn asElement(self: *Table) *Element {
    return self._proto._proto;
}
pub fn asNode(self: *Table) *Node {
    return self.asElement().asNode();
}

pub fn insertRow(self: *Table, index_: ?i32, page: *Page) !*TableRow {
    const element = try page.document.createElement("tr", null, page);
    const row = element.is(TableRow) orelse return error.Unexpected;

    const index = index_ orelse -1;
    if (index < 0) {
        _ = try self.asNode().appendChild(row.asNode(), page);
        return row;
    }

    var current: i32 = 0;
    var it = self.asNode().childrenIterator();
    while (it.next()) |child| {
        if (child.is(TableRow) == null) {
            continue;
        }

        if (current == index) {
            _ = try self.asNode().insertBefore(row.asNode(), child, page);
            return row;
        }

        current += 1;
    }

    _ = try self.asNode().appendChild(row.asNode(), page);
    return row;
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(Table);

    pub const Meta = struct {
        pub const name = "HTMLTableElement";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const insertRow = bridge.function(Table.insertRow, .{});
};

const testing = @import("../../../../testing.zig");
test "WebApi: HTML.Table" {
    try testing.htmlRunner("element/html/table.html", .{});
}
