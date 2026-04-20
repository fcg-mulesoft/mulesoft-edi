%dw 2.0
output application/json

var invoice = vars.initialPayload[0].b2bMessage default {}
var header = invoice.header default {}
var summary = invoice.summary default {}                          
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

fun toNumber(v) =
    if (v == null) 0
    else if (v is Number) v
    else if (v is String and trim(v) == "") 0
    else if (v is String and !(trim(v) matches /^-?\d+(\.\d+)?$/)) 0
    else (v as Number)

var rawItems = invoice.detail.invoice.itemDetails default []

var items =
    if (isEmpty(rawItems)) []
    else if (rawItems[0] is Array) flatten(rawItems)
    else rawItems

fun findMatch(item) =
    (p21Items filter (
        (upper($.supplier_part_no default "") == upper(item.vendorPartNo default "")) or
        (upper($.customer_part_number default "") == upper(item.buyerPartNo default "")) or
        (upper($.item_id default "") == upper(item.vendorPartNo default ""))
    ))[0] default {}

fun getSafeQty(item, matched) =
    do {
        var invQty = toNumber(item.qtyInvoiced)               
        var ordered = toNumber(matched.qty_ordered)
        var received = toNumber(matched.qty_received)
        var allowed = ordered - received
        ---
        if (allowed <= 0) 0
        else if (invQty > allowed) allowed
        else invQty
    } default 0

var calculatedTotal =
    items reduce ((i, acc = 0) ->
        acc + (toNumber(i.qtyInvoiced) * toNumber(i.unitPrice))  
    )

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

                { Name: "po_no", Value: p21.po_no },

                {
                  Name: "external_po_no",
                  Value:
                    if ((p21.po_type default "") == "D")
                        trim(p21.external_po_no default "")
                    else "",
                  IgnoreIfEmpty: true
                },

                { Name: "c_invoice_no", Value: header.invoiceNumber default "" },

                { Name: "c_invoice_date", Value: formatDate(header.invoiceDate) }, 

                {
                  Name: "branch_id",
                  Value: "",
                  IgnoreIfEmpty: true
                },
                {
                  Name: "location_id",
                  Value: "",
                  IgnoreIfEmpty: true
                },

                { Name: "vendor_id", Value: refs.internalVendorId default "" },

                { Name: "currency_code", Value: header.currencyCode default "" },

                { Name: "cf_invoice_total", Value: calculatedTotal }

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
            items map (item, index) ->
              do {

                var matched = findMatch(item)

                var itemId =
                    item.buyerPartNo
                    default item.vendorPartNo
                    default item.primaryItemNumber
                    default item.upcCode
                    default ""

                var qty = getSafeQty(item, matched)

                var uom = item.uom default ""                  

                ---
                {
                  Edits: [

                    { Name: "c_select_flag", Value: "Y" },

                    { Name: "line_no", Value: (index + 1) },

                    { Name: "item_id", Value: itemId },

                    { Name: "unit_of_measure", Value: uom },

                    { Name: "unit_size", Value: 1 },

                    { Name: "c_qty_to_invoice", Value: qty },

                    { Name: "pricing_unit", Value: uom },

                    { Name: "pricing_unit_size", Value: 1 },

                    { Name: "unit_price_display", Value: toNumber(item.unitPrice) }

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