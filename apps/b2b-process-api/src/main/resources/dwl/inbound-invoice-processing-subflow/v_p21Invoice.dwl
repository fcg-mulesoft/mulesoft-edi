%dw 2.0
output application/json



var poHeader   = vars.purchaseOrderData.value[0]

var b2bMessage = vars.initialPayload[0].b2bMessage
var b2bHeader  = b2bMessage.header
var b2bSummary = b2bMessage.summary
var itemLines  = b2bMessage.detail.invoice.itemDetails

fun edit(name: String, value: Any) = {
    "Name"          : name,
    "Value"         : (value default "") as String,
    "IgnoreIfEmpty" : true
}

fun formatDate(isoDate: String): String =
    isoDate[0 to 9] as Date { format: "yyyy-MM-dd" } as String { format: "MM/dd/yyyy" }

---
{
    "Name"           : "VendorInvoice",
    "Description"    : null,
    "UseCodeValues"  : true,
    "IgnoreDisabled" : true,
    "Transactions"   : [
        {
            "Status"       : "New",
            "DataElements" : [
                {
                    "Name"               : "TP_POHDR.tp_pohdr",
                    "BusinessObjectName" : null,
                    "Type"               : "Form",
                    "Keys"               : ["po_no"],
                    "Rows"               : [
                        {
                            "Edits": [
                                edit("po_no",                            b2bHeader.poNumber),
                                edit("vendor_invoice_flag",              "Y"),
                                edit("company_id",                       poHeader.company_no),
                                edit("branch_id",                        poHeader.branch_id),
                                edit("location_id",                      poHeader.location_id),
                                edit("c_invoice_no",                     b2bHeader.invoiceNumber),
                                edit("c_invoice_date",                   formatDate(b2bHeader.invoiceDate)),
                                edit("cf_invoice_total",                 b2bSummary.totalAmount as String { format: "#0.00" })
                            ],
                            "RelativeDateEdits": []
                        }
                    ]
                },
                {
                    "Name"               : "TP_POLINE.tp_poline",
                    "BusinessObjectName" : null,
                    "Type"               : "List",
                    "Keys"               : ["line_no"],
                    "Rows"               : itemLines map (item) -> {
                        "Edits": [
                            edit("line_no",          item.lineNo),
                            edit("c_select_flag",    "Y"),
                            edit("c_qty_to_invoice", item.qtyInvoiced),
                            edit("item_id",          item.vendorPartNo)
                        ],
                        "RelativeDateEdits": []
                    }
                }

            ],
            "Documents": null
        }
    ],
    "Query"                  : null,
    "FieldMap"               : [],
    "TransactionSplitMethod" : 0,
    "Parameters"             : null
}
