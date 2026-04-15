%dw 2.0
output application/json

var invoice = vars.initialPayload[0].b2bMessage default {}
var header = invoice.header default {}
var summary = invoice.Summary default {}
var refs = header.references default {}
var p21Items = vars.purchaseOrderData.value default []
fun norm(v) = (upper(trim((v default "") as String)) replace /[^A-Z0-9]/ with "")

var p21Index =
    p21Items reduce ((item, acc = {}) ->
        acc ++ {
            (norm(item.customer_part_number default "")): item,
            (norm(item.supplier_part_no default "")): item,
            (norm(item.item_id default "")): item
        }
    )

var items = invoice.data.invoice.itemDetails default []

var groupedItems =
    (items map (item) -> {
        productId: norm(
            item.primaryItemNumber 
            default item.buyerPartNumber 
            default item.vendorPartNumber 
            default item.upcCode
        ),
        quantity: (item.quantityInvoiced default 0) as Number,
        unitPrice: (item.unitPrice default 0) as Number,
        vendorPart: item.vendorPartNumber default ""
    }) groupBy $.productId

var itemErrorsMap =
    groupedItems mapObject ((itemList, productId) ->
        do {
            var totalQty = itemList reduce ((i, acc = 0) -> acc + i.quantity)
            var unitPrice = itemList[0].unitPrice
            var vendorPart = itemList[0].vendorPart
            var matched = p21Index[productId] default null

            var errors = flatten([

                if (matched == null)
                    [{entity: "Item", edi: productId, p21: null}]
                else [],

                if (
                    matched != null and
                    ((matched.qty_received default 0) + totalQty) > (matched.qty_ordered default 0)
                )
                    [{entity: "Quantity", edi: totalQty, p21: (matched.qty_ordered default 0) - (matched.qty_received default 0)}]
                else [],

                if (matched != null and (matched.unit_price default 0) != unitPrice)
                    [{entity: "Unit Price", edi: unitPrice, p21: matched.unit_price}]
                else [],

                if (matched != null and (matched.unit_quantity default 0) < totalQty)
                    [{entity: "Unit Quantity", edi: totalQty, p21: matched.unit_quantity}]
                else [],

                if (
                    matched != null and
                    !isEmpty(vendorPart) and
                    norm(vendorPart) != norm(matched.supplier_part_no)
                )
                    [{entity: "Supplier Part", edi: vendorPart, p21: matched.supplier_part_no}]
                else []

            ])

            ---
            if (isEmpty(errors)) {} else {(productId): errors}
        }
    )

var itemErrorsFlat = flatten(valuesOf(itemErrorsMap))

var invoiceTotal =
    groupedItems pluck ((value, key) ->
        value reduce ((i, acc = 0) -> acc + (i.quantity * i.unitPrice))
    ) reduce ((v, acc = 0) -> acc + v)

var totalErrors =
    if (abs((summary.totalInvoiceAmount default 0) - invoiceTotal) > 0.01)
        [{entity: "Invoice Total", edi: invoiceTotal, p21: summary.totalInvoiceAmount}]
    else []

var carrier = summary.carrierDetail default {}

var carrierErrors =
    if (
        !isEmpty(carrier.transportationMethodTypeCode) and
        norm(carrier.transportationMethodTypeCode) != norm(p21Items[0].carrier_id)
    )
        [{entity: "Carrier Code", edi: carrier.transportationMethodTypeCode, p21: p21Items[0].carrier_id}]
    else if (isEmpty(carrier.transportationMethodTypeCode))
        [{entity: "Carrier Code", edi: null, p21: p21Items[0].carrier_id}]
    else []


var vendorRefErrors =
    if (
        !isEmpty(refs.internalVendorId) and
        sizeOf(p21Items filter (
            norm($.supplier_id default "") == norm(refs.internalVendorId)
        )) == 0
    )
        [{entity: "Vendor Reference", edi: refs.internalVendorId, p21: p21Items[0].supplier_id default null}]
    else []

//var externalPoErrors =
//    if (
//        sizeOf(p21Items filter ($.po_type == "D")) > 0 and
//        !isEmpty(refs.purchaseOrderReference) and
//        norm(p21Items[0].external_po_no) != norm(refs.purchaseOrderReference)
//    )
//        [{entity: "External PO", edi: refs.purchaseOrderReference, p21: p21Items[0].external_po_no}]
//    else []

var bolErrors =
    if (
        !isEmpty(refs.billOfLading) and
        !isEmpty(p21Items[0].packing_slip_number default "") and
        norm(refs.billOfLading) != norm(p21Items[0].packing_slip_number)
    )
        [{entity: "Bill Of Lading", edi: refs.billOfLading, p21: p21Items[0].packing_slip_number}]
    else []


var allErrors =
    itemErrorsFlat
    ++ totalErrors
    ++ carrierErrors
    ++ vendorRefErrors
    ++ externalPoErrors
    ++ bolErrors

---
{
    isValid: isEmpty(allErrors),

    validationErrors: allErrors,

    itemWiseErrors: itemErrorsMap
}