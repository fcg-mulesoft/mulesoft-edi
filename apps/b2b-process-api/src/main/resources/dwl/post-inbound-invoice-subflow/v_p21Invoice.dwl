%dw 2.0

output application/json
 
var invoice = payload[0].b2bMessage default {}

var header = invoice.header default {}

var summary = invoice.Summary default {}

var rawItems = invoice.data.invoice.itemDetails default []
 
var items =

    if (sizeOf(rawItems) > 0 and rawItems[0] is Array)

        flatten(rawItems)

    else rawItems
 
var billTo =

    ((header.partyInformation default [])

        filter ($.entityIdentifierCode == "BT"))[0] default {}
 
fun formatDate(dateStr) =

    if (isEmpty(dateStr)) ""

    else (dateStr as DateTime {format: "yyyy-MM-dd'T'HH:mm:ssXXX"}) 

         as String {format: "MM/dd/yyyy"}
 
---

{

  Name: "VendorInvoice",

  Description: null,

  UseCodeValues: true,

  IgnoreDisabled: true,

  Transactions: [

    {

      Status: "New",

      DataElements: [

        {

          Name: "TP_POHDR.tp_pohdr",

          Type: "Form",

          Keys: ["po_no"],

          Rows: [

            {

              Edits: [

                { Name: "vendor_invoice_flag", Value: "Y" },

                { Name: "po_no", Value: header.purchaseOrderNumber default "" },

                { Name: "c_invoice_no", Value: header.invoiceNumber default "" },

                { Name: "c_invoice_date", Value: formatDate(header.invoiceIssueDate) },

                { Name: "vendor_name", Value: billTo.name default "", IgnoreIfEmpty: true },

                { Name: "order_date", Value: formatDate(header.purchaseOrderDate), IgnoreIfEmpty: true },

                { Name: "required_date", Value: formatDate(header.deliveryRequestedDate), IgnoreIfEmpty: true },

                { Name: "external_po_no", Value: header.purchaseOrderNumber default "", IgnoreIfEmpty: true },

                { Name: "terms_id", Value: header.termsOfSale.termsDescription default "", IgnoreIfEmpty: true },

                { Name: "cf_invoice_total", Value: summary.totalInvoiceAmount default 0 }

              ],

              RelativeDateEdits: []

            }

          ]

        },

        {

          Name: "TP_CHARGES.tp_charges",

          Type: "List",

          Keys: [],

          Rows:

            if (isEmpty(summary.serviceAllowanceCharge default [])) []

            else (summary.serviceAllowanceCharge default []) map (charge) -> {

              Edits: [

                { Name: "invoice_amt", Value: charge.SAC05 default "", IgnoreIfEmpty: true }

              ],

              RelativeDateEdits: []

            }

        },

        {

          Name: "TP_POLINE.tp_poline",

          Type: "List",

          Keys: ["line_no"],

          Rows:

            if (isEmpty(items)) []

            else items map (item) -> {

              Edits: [

                { Name: "c_select_flag", Value: "Y" },

                { Name: "item_id", Value: item.buyerPartNumber default item.primaryItemNumber default "", IgnoreIfEmpty: true },

                { Name: "unit_of_measure", Value: item.unitOfMeasurementCode default "" },

                { Name: "unit_size", Value: 1 },

                { Name: "c_qty_to_invoice", Value: item.quantityInvoiced default 0 },

                { Name: "pricing_unit", Value: item.unitOfMeasurementCode default "" },

                { Name: "pricing_unit_size", Value: 1 },

                { Name: "unit_price_display", Value: item.unitPrice default 0 },

                { Name: "line_no", Value: item.assignedIdentification default "" },

                { Name: "item_desc", Value: item.productDescription default "", IgnoreIfEmpty: true },

                { Name: "unit_quantity", Value: item.quantityInvoiced default 0 },

                { Name: "qty_received", Value: item.quantityInvoiced default 0 },

                { Name: "c_qty_vouched", Value: item.quantityInvoiced default 0 }

              ],

              RelativeDateEdits: []

            }

        }

      ],

      Documents: null

    }

  ],

  Query: null,

  FieldMap: [],

  TransactionSplitMethod: 0,

  Parameters: null

}
 