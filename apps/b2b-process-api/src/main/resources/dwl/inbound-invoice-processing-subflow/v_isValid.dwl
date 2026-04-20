%dw 2.0
output application/json



var DEBUG = false

var PRICE_TOLERANCE = 0.01

fun norm(v) =
    (upper(trim((v default "") as String)) replace /[^A-Z0-9]/ with "")

fun isMatch(a, b)       = norm(a) == norm(b)
fun isPriceMatch(a, b)  = abs((a default 0) - (b default 0)) <= PRICE_TOLERANCE
fun isMismatch(v)       = !(v default false)

var invoice     = vars.initialPayload[0].b2bMessage default {}
var header      = invoice.header default {}
var summary     = invoice.summary default {}                               // 
var p21Items    = vars.purchaseOrderData.value default []

var shipTo =
    ((header.partyInformation default [])
        filter ($.qualifier == "ST"))[0] default {}

var p21Ship = p21Items[0] default {}

var p21Index =
    p21Items reduce ((item, acc = {}) ->
        acc ++ {
            (norm(item.customer_part_number default "")): item,
            (norm(item.supplier_part_no default "")): item,
            (norm(item.item_id default "")): item
        }
    )

var items = invoice.detail.invoice.itemDetails default []

var groupedItems =
    (items map (item) -> {
        productId:  norm(item.buyerPartNo default item.vendorPartNo),
        quantity:   (item.qtyInvoiced default 0) as Number,               
        unitPrice:  (item.unitPrice default 0) as Number,
        uom:        item.uom default "",                                   
        buyerPartNo: item.buyerPartNo,
        vendorPartNo: item.vendorPartNo
    }) groupBy $.productId



var comparison =
    groupedItems pluck ((itemList, productId) -> do {

        var totalQty  = itemList reduce ((i, acc = 0) -> acc + i.quantity)
        var unitPrice = itemList[0].unitPrice
        var sample    = itemList[0]
        var matched   =
            p21Index[norm(sample.buyerPartNo)]
            default p21Index[norm(sample.vendorPartNo)]
            default {}

        ---
        {
            productKey: productId,

            supplier_part_no: {
                original: norm(sample.vendorPartNo default sample.buyerPartNo),
                odata:    matched.supplier_part_no,
                match:    !isEmpty(matched)
            },

            qty_ordered: {
                original: totalQty,
                odata:    matched.qty_ordered,
                match:    ((matched.qty_received default 0) + totalQty) <= (matched.qty_ordered default 0)
            },

            unit_price: {
                original: unitPrice,
                odata:    matched.unit_price,
                match:    isPriceMatch(unitPrice, matched.unit_price)
            },

            unit_quantity: {
                original: totalQty,
                odata:    matched.unit_quantity,
                match:    totalQty <= (matched.unit_quantity default 0)
            },


            ship2_name: {
                original: shipTo.name,
                odata:    p21Ship.ship2_name,
                match:    isEmpty(p21Ship.ship2_name) or isMatch(shipTo.name, p21Ship.ship2_name)
            },

            ship2_add1: {
                original: shipTo.address1,
                odata:    p21Ship.ship2_add1,
                match:    isEmpty(p21Ship.ship2_add1) or isMatch(shipTo.address1, p21Ship.ship2_add1)
            },
            ship2_add2: {
                original: shipTo.address2,
                odata:    p21Ship.ship2_add2,
                match:    isEmpty(p21Ship.ship2_add2) or isMatch(shipTo.address2, p21Ship.ship2_add2)
            },

            ship2_city: {
                original: shipTo.city,
                odata:    p21Ship.ship2_city,
                match:    isEmpty(p21Ship.ship2_city) or isMatch(shipTo.city, p21Ship.ship2_city)
            },


            ship2_state: {
                original: shipTo.state,
                odata:    p21Ship.ship2_state,
                match:    isEmpty(p21Ship.ship2_state) or isMatch(shipTo.state, p21Ship.ship2_state)
            },


            ship2_country: {
                original: shipTo.countryCode,
                odata:    p21Ship.ship2_country,
                match:    isEmpty(p21Ship.ship2_country) or isMatch(shipTo.countryCode, p21Ship.ship2_country)
            },

            ship2_zip: {
                original: shipTo.postalCode,
                odata:    p21Ship.ship2_zip,
                match:    isEmpty(p21Ship.ship2_zip) or isMatch(shipTo.postalCode, p21Ship.ship2_zip)
            },

            shipping_instruction: {
                original: header.shippingInstruction default "",
                odata:    p21Ship.shipping_instruction,
                match:    isEmpty(p21Ship.shipping_instruction) or
                          isEmpty(header.shippingInstruction default "") or   
                          isMatch(header.shippingInstruction default "", p21Ship.shipping_instruction)
            },

            carrier_id: {
                original: norm(summary.carrierDetail.carrierCode),         
                odata:    norm(p21Ship.carrier_id),
                match:    isEmpty(norm(summary.carrierDetail.carrierCode)) or
                          isEmpty(norm(p21Ship.carrier_id)) or
                          isMatch(summary.carrierDetail.carrierCode, p21Ship.carrier_id)
            },

            external_po_no: {
                original: header.poNumber,                                
                odata:    p21Ship.external_po_no,
                match:    sizeOf(p21Items filter ($.po_type == "D")) == 0 or
                          isEmpty(p21Ship.external_po_no) or
                          isMatch(header.poNumber, p21Ship.external_po_no) 
            },

            customer_part_number: {
                original: sample.buyerPartNo,
                odata:    matched.customer_part_number,
                match:    true                                             
            }
        }
    })

var itemErrors =
    (comparison map (line) -> do {
        var errs =
            if (isMismatch(line.supplier_part_no.match))
                ["Supplier part number not found in P21"]
            else flatten([
                if (isMismatch(line.qty_ordered.match))   ["Quantity exceeds ordered amount"] else [],
                if (isMismatch(line.unit_price.match))    ["Unit price mismatch"]              else [],
                if (isMismatch(line.unit_quantity.match)) ["Unit quantity exceeded"]           else []
            ])
        ---
        if (sizeOf(errs) > 0)
            {(line.productKey): errs}
        else {}
    }) reduce ((item, acc = {}) -> acc ++ item)

var shipToErrors =
    flatten([
        if (isMismatch(comparison[0].ship2_name.match))             ["ShipTo Name mismatch"]              else [],
        if (isMismatch(comparison[0].ship2_add1.match))             ["ShipTo Address1 mismatch"]          else [],
        if (isMismatch(comparison[0].ship2_add2.match))             ["ShipTo Address2 mismatch"]          else [],
        if (isMismatch(comparison[0].ship2_city.match))             ["ShipTo City mismatch"]              else [],
        if (isMismatch(comparison[0].ship2_state.match))            ["ShipTo State mismatch"]             else [],
        if (isMismatch(comparison[0].ship2_zip.match))              ["ShipTo Zip mismatch"]               else [],
        if (isMismatch(comparison[0].ship2_country.match))          ["ShipTo Country mismatch"]           else [],
        if (isMismatch(comparison[0].shipping_instruction.match))   ["Shipping instruction mismatch"]     else []
    ])

var carrierErrors =
    flatten([
        if (isMismatch(comparison[0].carrier_id.match)) ["Carrier ID mismatch"] else []
    ])

var externalPoErrors =
    flatten([
        if (isMismatch(comparison[0].external_po_no.match)) ["External PO number mismatch"] else []
    ])

var customerPartErrors =
    flatten([
        if (isMismatch(comparison[0].customer_part_number.match)) ["Customer part number mismatch"] else []
    ])

var warnings = []

var errorCount =
    sizeOf(flatten(valuesOf(itemErrors))) +
    sizeOf(shipToErrors) +
    sizeOf(carrierErrors) +
    sizeOf(externalPoErrors) +
    sizeOf(customerPartErrors)



---
(if (DEBUG)
    {
        debug: {
            comparison: comparison,
            errorCount: errorCount
        },
        isValid: errorCount == 0,
        validationErrors: {
            itemErrors:          itemErrors,
            shipToErrors:        shipToErrors,
            carrierErrors:       carrierErrors,
            externalPoErrors:    externalPoErrors,
            customerPartErrors:  customerPartErrors
        },
        warnings: warnings
    }
else
    {
        isValid: errorCount == 0,
        validationErrors: {
            itemErrors:          itemErrors,
            shipToErrors:        shipToErrors,
            carrierErrors:       carrierErrors,
            externalPoErrors:    externalPoErrors,
            customerPartErrors:  customerPartErrors
        },
        warnings: warnings
    }
)
