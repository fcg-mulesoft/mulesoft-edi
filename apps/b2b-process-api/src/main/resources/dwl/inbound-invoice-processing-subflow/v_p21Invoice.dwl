%dw 2.0
output application/json

var invoice = vars.initialPayload[0].b2bMessage default {}
var header = invoice.header default {}
var summary = invoice.Summary default {}
var refs = header.references default {}

var p21Items = vars.purchaseOrderData.value default []
var p21 = p21Items[0] default {}

fun getVal(v) =
    if (v is Array) v[0] else v

fun formatDate(v) =
    do {
        var val = getVal(v)
        ---
        if (isEmpty(val)) ""
        else (val as DateTime {format: "yyyy-MM-dd'T'HH:mm:ssXXX"})
             as String {format: "MM/dd/yyyy"}
    }
var rawItems = invoice.data.invoice.itemDetails default []

var items =
    if (isEmpty(rawItems)) []
    else if (rawItems[0] is Array) flatten(rawItems)
    else rawItems

---
{
  Name: "VendorInvoice",
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

                { Name: "po_no", Value: getVal(header.purchaseOrderNumber) },

                {
                  Name: "external_po_no",
                  Value:
                    if ((p21.po_type default "") == "D")
                        getVal(refs.purchaseOrderReference default header.purchaseOrderNumber)
                    else "",
                  IgnoreIfEmpty: true
                },

                { Name: "c_invoice_no", Value: header.invoiceNumber default "" },

                { Name: "c_invoice_date", Value: formatDate(header.invoiceIssueDate) },

                { Name: "vendor_id", Value: refs.internalVendorId default "" },

                { Name: "terms_id", Value: header.termsOfSale.typeCode default "" },

                { Name: "currency_code", Value: header.currencyCode default "" },

                { Name: "bill_of_lading", Value: refs.billOfLading default "" },

                { Name: "cf_invoice_total", Value: summary.totalInvoiceAmount default 0 }

              ],
              RelativeDateEdits: []
            }
          ]
        },

        {
          Name: "TP_POLINE.tp_poline",
          Type: "List",
          Keys: ["line_no"],
          Rows:
            if (isEmpty(items)) []
            else items map (item) ->
              do {
                var itemId =
                    item.buyerPartNumber
                    default item.primaryItemNumber
                    default item.vendorPartNumber
                    default item.upcCode
                    default ""

                var qty =
                    item.quantityInvoiced
                    default item.quantityOrdered
                    default 0

                var uom =
                    item.unitOfMeasurementCode
                    default item.uom
                    default ""

                var lineNo =
                    item.assignedIdentification
                    default item.lineNo
                    default ""

                ---
                {
                  Edits: [

                    { Name: "c_select_flag", Value: "Y" },

                    { Name: "line_no", Value: lineNo },

                    { Name: "item_id", Value: itemId, IgnoreIfEmpty: true },

                    { Name: "unit_of_measure", Value: uom },

                    { Name: "unit_size", Value: 1 },

                    { Name: "c_qty_to_invoice", Value: qty },

                    { Name: "pricing_unit", Value: uom },

                    { Name: "pricing_unit_size", Value: 1 },

                    { Name: "unit_price_display", Value: item.unitPrice default 0 },

                    {
                      Name: "item_desc",
                      Value:
                        item.productDescription
                        default item.description
                        default "",
                      IgnoreIfEmpty: true
                    }

                  ],
                  RelativeDateEdits: []
                }
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