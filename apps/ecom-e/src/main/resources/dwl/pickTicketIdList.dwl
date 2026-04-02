%dw 2.0
output application/json
var tabpage = flatten(payload.Transactions.DataElements) filter ((item, index) -> item.Name == "TABPAGE_17.tabpage_ship")
var rows = flatten(tabpage map ((item, index) -> item.Rows.Edits))
---
{
       pickTicketIds: (flatten(rows) filter ((item, index) -> item.Name == "oe_order_item_id")) map ((item, index) ->  item.Value)
}