%dw 2.0
output application/json

var viewData = (vars.purchaseOrderData.value default []) as Array

fun formatDate(d) =
    if (d is String) ((d as DateTime) as String { format: "MM/dd/yyyy" })
    else ""

fun lookupItemId(poNum: String, lineNo: Number, supplierPartNo: String | Null) =
    (viewData filter (v) ->
        (v.po_no as String) == (poNum as String)
        and (v.line_no as Number) == lineNo
        and (trim(v.supplier_part_no default "")) == (trim(supplierPartNo default ""))
    )[0].item_id default null
---
{
    UseCodeValues: true,
    IgnoreDisabled: true,
    Transactions: payload map (wrapper) -> do {
        var txn = wrapper.b2bMessage
        var items = txn.detail.itemDetails default []
        var poNum = txn.header.poNumber default ""
        var supplierAcknowledgement = txn.header.supplierAcknowledgement default poNum

        var matchedItems = items map (item) -> do {
            var directItemId = item.buyerPartNo default null
            var resolvedItemId =
                if (directItemId != null) directItemId
                else lookupItemId(poNum, item.lineNo, item.vendorPartNo)
            ---
            {
                item: item,
                lineNo: item.lineNo,
                itemId: resolvedItemId
            }
        }
        ---
        {
            Status: "New",
            DataElements: [{
                Name: "TABPAGE_1.tp_1_dw_1",
                Type: "Form",
                Keys: ["po_no"],
                Rows: [{
                    Edits: [{
                        Name: "po_no",
                        Value: poNum
                    },
                    {
                        Name: "ufc_po_hdr_ud_supplier_acknowledgement",
                        Value: supplierAcknowledgement
                    }]
                }]
            },
            {
                Name: "TABPAGE_17.tp_17_dw_17",
                Type: "List",
                Keys: ["line_no", "item_id"],
                Rows: matchedItems map (m) -> do {
                    var item = m.item
                    ---
                    {
                        Edits: [{
                            Name: "line_no",
                            Value: m.lineNo as String
                        },
                        {
                            Name: "item_id",
                            Value: m.itemId
                        },
                        {
                            Name: "expected_ship_date",
                            Value: formatDate(item.acknowledgments[0].scheduledDate)
                        },
                        {
                            Name: "acknowledged",
                            Value: "Y"
                        },
                        {
                            Name: "acknowledged_date",
                            Value: formatDate(item.acknowledgments[0].scheduledDate)
                        }]
                    }
                }
            },
            {
                Name: "TABPAGE_18.extended_info",
                Type: "List",
                Keys: ["item_id"],
                Rows: matchedItems map (m) -> do {
                    var item = m.item
                    ---
                    {
                        Edits: [{
                            Name: "item_id",
                            Value: m.itemId
                        },
                        {
                            Name: "expected_ship_date",
                            Value: formatDate(item.acknowledgments[0].scheduledDate)
                        },
                        {
                            Name: "acknowledged",
                            Value: "Y"
                        },
                        {
                            Name: "acknowledged_date",
                            Value: formatDate(item.acknowledgments[0].scheduledDate)
                        }]
                    }
                }
            }]
        }
    }
}