%dw 2.0
output application/json

fun getValue(edits, key) =
    (edits filter ($.Name == key))[0].Value default null

var txns = payload.TransactionSetResult.Results.Transactions.*Transaction
var msgs = payload.TransactionSetResult.Messages.*string

---
txns map (txn, index) -> {
    messageIndex: index + 1,
    message: msgs[index] default null,
    po_no: getValue(txn.DataElements.DataElement.Rows.Row.Edits.*Edit, "po_no"),
    vendor_id: getValue(txn.DataElements.DataElement.Rows.Row.Edits.*Edit, "vendor_id")
}