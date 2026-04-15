%dw 2.0

output application/json

var invoice = vars.initialPayload[0].b2bMessage default {}

var header = invoice.header default {}

var summary = invoice.Summary default {}

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

        productId: norm(item.buyerPartNumber),

        quantity: (item.quantityInvoiced default 0) as Number,

        unitPrice: (item.unitPrice default 0) as Number,

        uom: item.unitOfMeasurementCode default ""

    }) groupBy $.productId
 
var itemErrors =

    groupedItems pluck ((itemList, productId) ->

        do {

            var totalQty = itemList reduce ((i, acc = 0) -> acc + i.quantity)

            var unitPrice = itemList[0].unitPrice

            var matched = p21Index[productId] default null
 
            var errors = flatten([

                if (

                    matched != null and

                    ((matched.qty_received default 0) + totalQty) > (matched.qty_ordered default 0)

                )

                    ["Quantity exceeds allowed"]

                else [],

                if (matched != null and (matched.unit_price default 0) != unitPrice)

                    ["Unit price mismatch"]

                else [],

                if (matched != null and (matched.unit_quantity default 0) < totalQty)

                    ["Unit quantity exceeded"]

                else []

            ])
 
            ---

            if (isEmpty(errors)) {}

            else {(productId): errors}

        }

    )

    reduce ((item, acc = {}) -> acc ++ item)
 
var invoiceTotal =

    groupedItems pluck ((value, key) ->

        value reduce ((i, acc = 0) -> acc + (i.quantity * i.unitPrice))

    ) reduce ((v, acc = 0) -> acc + v)
 
var totalErrors =

    if (abs((summary.totalInvoiceAmount default 0) - invoiceTotal) > 0.01)

        ["Invoice total mismatch"]

    else []
 
var shipTo =

    ((header.partyInformation default [])

        filter ($.entityIdentifierCode == "ST"))[0] default {}
 
var p21Ship = p21Items[0] default {}
 
var shipToErrors = flatten([

    if (!isEmpty(p21Ship.ship2_name) and norm(shipTo.name) != norm(p21Ship.ship2_name)) ["ShipTo Name mismatch"] else [],

    if (!isEmpty(p21Ship.ship2_add1) and norm(shipTo.addressLine1) != norm(p21Ship.ship2_add1)) ["ShipTo Address1 mismatch"] else [],

    if (!isEmpty(p21Ship.ship2_city) and norm(shipTo.cityName) != norm(p21Ship.ship2_city)) ["ShipTo City mismatch"] else [],

    if (!isEmpty(p21Ship.ship2_state) and norm(shipTo.stateOrProvinceCode) != norm(p21Ship.ship2_state)) ["ShipTo State mismatch"] else [],

    if (!isEmpty(p21Ship.ship2_zip) and norm(shipTo.postalCode) != norm(p21Ship.ship2_zip)) ["ShipTo Zip mismatch"] else [],

    if (!isEmpty(p21Ship.ship2_country) and norm(shipTo.countryCode) != norm(p21Ship.ship2_country)) ["ShipTo Country mismatch"] else []

])
 
var carrier = summary.carrierDetail default {}
 
var ediTransportCode = norm(carrier.transportationMethodTypeCode)

var p21CarrierId     = norm(p21Items[0].carrier_id)
 
var carrierErrors =

    if (

        !isEmpty(ediTransportCode) and

        !isEmpty(p21CarrierId) and

        ediTransportCode != p21CarrierId

    )

        ["Carrier code mismatch"]

    else []
// 
//var externalPoErrors =
//
//    if (
//
//        sizeOf(p21Items filter ($.po_type == "D")) > 0 and
//
//        !isEmpty(p21Items[0].external_po_no) and
//
//        norm(p21Items[0].external_po_no) != norm(header.purchaseOrderNumber)
//
//    )
//
//        ["External PO mismatch"]
//
//    else []
 
var customerPartErrors =

    if (

        sizeOf(p21Items filter (

            $.po_type == "D" and !isEmpty($.sales_order_number)

        )) > 0 and

        isEmpty(items[0].buyerPartNumber)

    )

        ["Missing Customer Part"]

    else []
 
var allErrors =

    totalErrors

    ++ shipToErrors

    ++ carrierErrors

    ++ customerPartErrors

    ++ flatten(valuesOf(itemErrors))
 
---

{

    isValid: isEmpty(allErrors),

    validationErrors: {

        itemErrors: itemErrors,

        totalErrors: totalErrors,

        shipToErrors: shipToErrors,

        carrierErrors: carrierErrors,

        customerPartErrors: customerPartErrors

    }

}
 