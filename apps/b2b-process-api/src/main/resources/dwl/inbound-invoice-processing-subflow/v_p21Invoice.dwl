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
                                edit("vendor_id",                        ""),
                                edit("supplier_id",                      ""),
                                edit("division_id",                      ""),
                                edit("buyer_id",                         ""),
                                edit("processing_type",                  ""),
                                edit("source_type_cd",                   ""),
                                edit("c_invoice_no",                     b2bHeader.invoiceNumber),
                                edit("period",                           ""),
                                edit("year_for_period",                  ""),
                                edit("c_invoice_date",                   formatDate(b2bHeader.invoiceDate)),
                                edit("c_voucher_desc",                   ""),
                                edit("terms_id",                         ""),
                                edit("c_terms_due_date",                 ""),
                                edit("c_net_due_date",                   ""),
                                edit("document_id",                      ""),
                                edit("c_total_freight",                  ""),
                                edit("c_terms_amt",                      ""),
                                edit("use_variance_levels_validations",  ""),
                                edit("purchase_group_id",                ""),
                                edit("approved",                         ""),
                                edit("purchase_transfer_group_desc",     ""),
                                edit("vendor_name",                      ""),
                                edit("supplier_name",                    ""),
                                edit("company_name",                     ""),
                                edit("branch_description",               ""),
                                edit("division_name",                    ""),
                                edit("location_name",                    ""),
                                edit("buyer_name",                       ""),
                                edit("order_date",                       ""),
                                edit("expected_date",                    ""),
                                edit("required_date",                    ""),
                                edit("external_po_no",                   ""),
                                edit("expected_ship_date",               ""),
                                edit("supplier_release_no",              ""),
                                edit("po_type",                          ""),
                                edit("c_charges",                        ""),
                                edit("c_total_line_cost",                ""),
                                edit("cf_invoice_total",                 b2bSummary.totalAmount as String { format: "#0.00" })
                            ],
                            "RelativeDateEdits": []
                        }
                    ]
                },

                {
                    "Name"               : "TP_CHARGES.tp_charges",
                    "BusinessObjectName" : null,
                    "Type"               : "List",
                    "Keys"               : [],
                    "Rows"               : [
                        {
                            "Edits": [
                                edit("invoice_amt",     ""),
                                edit("sac_id",          ""),
                                edit("account_no",      ""),
                                edit("purchase_desc",   ""),
                                edit("account_no_desc", ""),
                                edit("cf_rowfocuisind", ""),
                                edit("cf_charge_total", "")
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
                            edit("item_id",          item.vendorPartNo),
                            edit("qty_received",     ""),
                            edit("c_qty_vouched",    "")
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
