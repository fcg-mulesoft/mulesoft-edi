%dw 2.0
output application/json

var DEBUG = true

fun norm(v) =
  (upper(trim((v default "") as String)) replace /[^A-Z0-9]/ with "")

fun isMatch(a, b) = norm(a) == norm(b)
fun isMismatch(v) = !(v default false)

var ediLines = payload.b2bMessage.detail.itemDetails
var odataLines = vars.purchaseOrderData.value

var header = payload.initialPayload[0].b2bMessage.header
var shipTo = header.partyInformation filter ($.qualifier == "ST") default []

var p21Index =
    odataLines reduce ((item, acc = {}) ->
        acc ++ {
            (norm(item.customer_part_number default "")): item,
            (norm(item.supplier_part_no default "")): item,
            (norm(item.item_id default "")): item
        }
    )

var groupedEDI =
    ediLines groupBy (norm($.buyerPartNo default $.vendorPartNo))

var PRICE_TOLERANCE = 0.01

fun isPriceMatch(a, b) =
    abs((a default 0) - (b default 0)) <= PRICE_TOLERANCE

var comparison =
    groupedEDI pluck (items, key) -> do {

        var totalQty =
            items reduce ((i, acc = 0) -> acc + (i.quantityOrdered default 0))

        var sample = items[0]

        var matched =
            p21Index[norm(sample.buyerPartNo)]
            default p21Index[norm(sample.vendorPartNo)]
            default {}

        ---
        {
            productKey: key,
            lineNos: items.*lineNo,

            supplier_part_no: {
                original: sample.vendorPartNo,
                odata: matched.supplier_part_no,
                match: isMatch(sample.vendorPartNo, matched.supplier_part_no)
            },

            qty_ordered: {
                original: totalQty,
                odata: matched.qty_ordered,
                match: isMatch(totalQty, matched.qty_ordered)
            },

            qty_received: {
                original: 0,
                odata: matched.qty_received,
                match: isMatch(0, matched.qty_received)
            },

            unit_price: {
                original: sample.unitPrice,
                odata: matched.unit_price,
                match: isPriceMatch(sample.unitPrice, matched.unit_price)
            },

            unit_quantity: {
                original: totalQty,
                odata: matched.unit_quantity,
                match: isMatch(totalQty, matched.unit_quantity)
            },

            config_1: {
                original: null,
                odata: matched.config_1,
                match: isMatch(null, matched.config_1)
            },

            config_2: {
                original: null,
                odata: matched.config_2,
                match: isMatch(null, matched.config_2)
            },

            carrier_id: {
                original: null,
                odata: matched.carrier_id,
                match: isMatch(null, matched.carrier_id)
            },

            ship2_name: {
                original: shipTo[0].name,
                odata: matched.ship2_name,
                match: isMatch(shipTo[0].name, matched.ship2_name)
            },

            ship2_add1: {
                original: shipTo[0].address1,
                odata: matched.ship2_add1,
                match: isMatch(shipTo[0].address1, matched.ship2_add1)
            },

            ship2_add2: {
                original: null,
                odata: matched.ship2_add2,
                match: isMatch(null, matched.ship2_add2)
            },

            ship2_city: {
                original: shipTo[0].city,
                odata: matched.ship2_city,
                match: isMatch(shipTo[0].city, matched.ship2_city)
            },

            ship2_state: {
                original: shipTo[0].state,
                odata: matched.ship2_state,
                match: isMatch(shipTo[0].state, matched.ship2_state)
            },

            ship2_country: {
                original: shipTo[0].countryCode,
                odata: matched.ship2_country,
                match: isMatch(shipTo[0].countryCode, matched.ship2_country)
            },

            ship2_zip: {
                original: shipTo[0].postalCode,
                odata: matched.ship2_zip,
                match: isMatch(shipTo[0].postalCode, matched.ship2_zip)
            },

            external_po_no: {
                original: header.purchaseOrderNumber,
                odata: matched.external_po_no,
                match: isMatch(header.purchaseOrderNumber, matched.external_po_no)
            },

            carrier_code: {
                original: null,
                odata: matched.carrier_code,
                match: isMatch(null, matched.carrier_code)
            },

            shipping_instruction: {
                original: header.shipping_instruction,
                odata: matched.shipping_instruction,
                match: isMatch(header.shipping_instruction, matched.shipping_instruction)
            },

            customer_part_number: {
                original: sample.buyerPartNo,
                odata: matched.customer_part_number,
                match:
                    if ((matched.po_type default "") == "D" and (matched.sales_order_number default null) != null)
                        isMatch(sample.buyerPartNo, matched.customer_part_number)
                    else true
            }
        }
    }

var itemErrors =
    (comparison map (line) -> do {
        var errs =
            flatten([
                if (isMismatch(line.supplier_part_no.match)) ["Supplier Part mismatch"] else [],
                if (isMismatch(line.qty_ordered.match)) ["Qty Ordered mismatch"] else [],
                if (isMismatch(line.qty_received.match)) ["Qty Received mismatch"] else [],
                if (isMismatch(line.unit_price.match)) ["Unit Price mismatch"] else [],
                if (isMismatch(line.unit_quantity.match)) ["Unit Quantity mismatch"] else [],
                if (isMismatch(line.config_1.match)) ["Config1 missing"] else [],
                if (isMismatch(line.config_2.match)) ["Config2 missing"] else [],
                if (isMismatch(line.shipping_instruction.match)) ["Shipping Instruction missing"] else []
            ])
        ---
        if (sizeOf(errs) > 0)
            {(line.productKey): errs}
        else {}
    }) reduce ((item, acc = {}) -> acc ++ item)

var shipToErrors =
    flatten([
        if (isMismatch(comparison[0].ship2_name.match)) ["ShipTo Name mismatch"] else [],
        if (isMismatch(comparison[0].ship2_add1.match)) ["ShipTo Address1 mismatch"] else [],
        if (isMismatch(comparison[0].ship2_add2.match)) ["ShipTo Address2 mismatch"] else [],
        if (isMismatch(comparison[0].ship2_city.match)) ["ShipTo City mismatch"] else [],
        if (isMismatch(comparison[0].ship2_state.match)) ["ShipTo State mismatch"] else [],
        if (isMismatch(comparison[0].ship2_country.match)) ["ShipTo Country mismatch"] else [],
        if (isMismatch(comparison[0].ship2_zip.match)) ["ShipTo Zip mismatch"] else []
    ])

var carrierErrors =
    flatten([
        if (isMismatch(comparison[0].carrier_id.match)) ["Carrier missing"] else []
    ])

var externalPoErrors =
    flatten([
        if (isMismatch(comparison[0].external_po_no.match)) ["External PO mismatch"] else []
    ])

var customerPartErrors =
    flatten([
        if (isMismatch(comparison[0].customer_part_number.match)) ["Customer Part mismatch"] else []
    ])

var warnings =
    flatten([
        if (isMismatch(comparison[0].carrier_code.match)) ["Carrier Code mismatch"] else []
    ])

var totalErrors = []

var errorCount =
    sizeOf(itemErrors) +
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
            itemErrors: itemErrors,
            totalErrors: totalErrors,
            shipToErrors: shipToErrors,
            carrierErrors: carrierErrors,
            externalPoErrors: externalPoErrors,
            customerPartErrors: customerPartErrors
        },
        warnings: warnings
    }
 else
    {
        isValid: errorCount == 0,
        validationErrors: {
            itemErrors: itemErrors,
            totalErrors: totalErrors,
            shipToErrors: shipToErrors,
            carrierErrors: carrierErrors,
            externalPoErrors: externalPoErrors,
            customerPartErrors: customerPartErrors
        },
        warnings: warnings
    }
)