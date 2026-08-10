%dw 2.0
output application/json
var DEBUG = true

fun hasValue(v) = v != null and (v is String and trim(v) != "" or !(v is String))
fun norm(v) =
    if (v is String)
        (upper(trim(v)) replace /[^A-Z0-9]/ with "")
    else if (v is Number)
        (v as String)
    else
        ""
fun isMatch(a, b) = hasValue(a) and hasValue(b) and (norm(a) == norm(b))
fun normalizeWords(text) =
    if (!hasValue(text))
        []
    else
        upper(trim((text as String))) splitBy /\s+/
fun wordMatchPercentage(a, b) =
    do {
        var words1 = normalizeWords(a)
        var words2 = normalizeWords(b)
        var matchedWords = sizeOf(words1 filter (word) -> words2 contains word)
        var totalWords = max([sizeOf(words1), sizeOf(words2)])
        ---
        if (totalWords == 0) 0 else (matchedWords * 100.0) / totalWords
    }
fun addressMatchPercentage(a, b) = wordMatchPercentage(a, b)
fun nameMatchPercentage(a, b) = wordMatchPercentage(a, b)
fun isMismatch(v) = !(v default false)
fun first(v) = if (v is Array and sizeOf(v) > 0) v[0] else v
fun toNumber(v) = if (v is Array) (v[0] default null) else v
fun normalizeZip(zip) =
    if (!hasValue(zip))
        ""
    else
        do {
            var z = ((zip as String) replace /[^0-9]/ with "")
            ---
            if (sizeOf(z) >= 5) z[0 to 4] else z
        }
fun isZipMatch(a, b) = hasValue(a) and hasValue(b) and (normalizeZip(a) == normalizeZip(b))
fun isPriceMatch(a, b) =
    if (!hasValue(a) or !hasValue(b))
        false
    else
        abs((toNumber(a) default 0) - (toNumber(b) default 0)) <= 0.01
fun lineKey(v) = if (hasValue(v)) (v as String) else "UNKNOWN_LINE"

var payloadMissing = (payload == null or (payload is Array and sizeOf(payload) == 0))
var root = if (payloadMissing) {} else payload[0] default {}
var b2bMessage = root.b2bMessage default {}
var headerMissing = (b2bMessage.header == null)
var header = b2bMessage.header default {}
var ediLines = b2bMessage.detail.itemDetails default []
var ediLinesMissing = (sizeOf(ediLines) == 0)

var odataMissing = (vars.purchaseOrderData == null)
var odataLines = vars.purchaseOrderData.value default []
var odataLinesMissing = (!odataMissing and sizeOf(odataLines) == 0)

var sourceErrors =
    flatten([
        if (payloadMissing) ["EDI 855 payload is missing or empty"] else [],
        if (headerMissing) ["EDI 855 header block is missing"] else [],
        if (ediLinesMissing) ["No item lines found in EDI 855 detail.itemDetails"] else [],
        if (odataMissing) ["P21 PO OData response (purchaseOrderData) is missing"] else [],
        if (odataLinesMissing) ["P21 PO OData response contains no line items"] else []
    ])

var partyInfo = header.partyInformation default []
var shipToRaw = (partyInfo filter ($.qualifier == "ST"))[0]
var shipToMissing = (shipToRaw == null)
var shipTo = {
    name: shipToRaw.name,
    address1: shipToRaw.address1,
    city: shipToRaw.city,
    state: shipToRaw.state,
    postalCode: shipToRaw.postalCode
}

var firstOdataLine = odataLines[0]
var firstOdataLineMissing = (firstOdataLine == null)

// scenario 1: buyerPart present -> match on item_id
// scenario 2: buyerPart absent, vendorPart present -> match on line_no + supplier_part_no
// scenario 3: buyerPart and vendorPart both absent -> match on line_no alone
fun matchLine(buyerPart, vendorPart, lineNo, odataLines) =
    do {
        var hasBuyer = hasValue(buyerPart)
        var hasVendor = hasValue(vendorPart)
        var hasLine = hasValue(lineNo)

        var byItem =
            if (hasBuyer)
                (odataLines filter (norm($.item_id) == norm(buyerPart)))[0]
            else
                null

        var byLineAndSupplier =
            if (byItem == null and hasVendor and hasLine)
                (odataLines filter (
                    (norm($.line_no) == norm(lineNo))
                    and (norm($.supplier_part_no) == norm(vendorPart))
                ))[0]
            else
                null

        var byLineOnly =
            if (byItem == null and byLineAndSupplier == null and hasLine)
                (odataLines filter (norm($.line_no) == norm(lineNo)))[0]
            else
                null

        var matched = byItem default (byLineAndSupplier default byLineOnly)
        var matchedBy =
            if (byItem != null) "item_id"
            else if (byLineAndSupplier != null) "line_no+supplier_part_no"
            else if (byLineOnly != null) "line_no"
            else "none"
        ---
        {
            matched: matched,
            matchedBy: matchedBy,
            identityValidated: (byItem != null)
        }
    }

var comparison =
    ediLines map (line, idx) ->
        do {
            var lineNo = first(line.lineNo)
            var buyerPart = first(line.buyerPartNo)
            var vendorPart = first(line.vendorPartNo)

            var matchResult = matchLine(buyerPart, vendorPart, lineNo, odataLines)
            var matched = matchResult.matched
            var isFound = (matched != null)
            var m = matched default {}
            var identityValidated = matchResult.identityValidated

            var orderedQty = toNumber(line.quantityOrdered)
            var receivedQty = m.qty_received
            var allowedQty = m.qty_ordered
            var linePrice = toNumber(line.unitPrice)
            var odataPrice = m.unit_price
            var addressPercentage = addressMatchPercentage(shipTo.address1, m.ship2_add1)
            var namePercentage = nameMatchPercentage(shipTo.name, m.ship2_name)

            var missingFields =
                if (!isFound)
                    []
                else
                    flatten([
                        if (!hasValue(m.supplier_part_no)) ["Supplier part number missing in PO data"] else [],
                        if (!hasValue(allowedQty)) ["Ordered quantity missing in PO data"] else [],
                        if (!hasValue(odataPrice)) ["Unit price missing in PO data"] else []
                    ])

            var lineIdentityMissing =
                if (!hasValue(buyerPart) and !hasValue(vendorPart))
                    ["EDI line has no buyerPartNo or vendorPartNo to match on"]
                else
                    []
            ---
            {
                lineNo: lineNo,
                buyerPart: buyerPart,
                vendorPart: vendorPart,
                matchedBy: matchResult.matchedBy,
                line_match: isFound,
                buyer_match: isFound,
                supplier_part_no: {
                    original: vendorPart,
                    odata: m.supplier_part_no,
                    match:
                        if (!isFound or !hasValue(m.supplier_part_no))
                            false
                        else if (!identityValidated)
                            true
                        else
                            isMatch(vendorPart, m.supplier_part_no)
                },
                qty_ordered: {
                    original: orderedQty,
                    odata: allowedQty,
                    match:
                        if (!isFound or !hasValue(orderedQty) or !hasValue(allowedQty))
                            false
                        else
                            ((orderedQty default 0) + (receivedQty default 0)) <= allowedQty
                },
                unit_price: {
                    original: linePrice,
                    odata: odataPrice,
                    match: if (!isFound) false else isPriceMatch(linePrice, odataPrice)
                },
                shipTo: {
                    original: shipTo,
                    odata: {
                        name: m.ship2_name,
                        address1: m.ship2_add1,
                        city: m.ship2_city,
                        state: m.ship2_state,
                        postalCode: m.ship2_zip
                    },
                    match: {
                        name: namePercentage >= 50,
                        address1: isMatch(shipTo.address1, m.ship2_add1),
                        city: isMatch(shipTo.city, m.ship2_city),
                        state: isMatch(shipTo.state, m.ship2_state),
                        postalCode: isZipMatch(shipTo.postalCode, m.ship2_zip)
                    },
                    addressMatchPercentage: addressPercentage,
                    nameMatchPercentage: namePercentage
                },
                lineErrors: lineIdentityMissing ++ missingFields
            }
        }

var itemErrors =
    (comparison map (line) -> {
        (lineKey(line.lineNo)):
            flatten([
                if (isMismatch(line.line_match))
                    ["Item line not found in PO"]
                else
                    [],
                line.lineErrors,
                if (line.line_match and isMismatch(line.supplier_part_no.match) and hasValue(line.supplier_part_no.odata))
                    ["Supplier part number mismatch"]
                else
                    [],
                if (line.line_match and isMismatch(line.qty_ordered.match) and hasValue(line.qty_ordered.odata) and hasValue(line.qty_ordered.original))
                    ["Quantity exceeds ordered amount"]
                else
                    [],
                if (line.line_match and isMismatch(line.unit_price.match) and hasValue(line.unit_price.odata) and hasValue(line.unit_price.original))
                    ["Unit Price Mismatch"]
                else
                    []
            ])
    })
    reduce ((item, acc = {}) -> acc ++ item)
    filterObject (sizeOf($) > 0)

var shipToErrors =
    if (shipToMissing)
        ["Ship To (ST) party information missing in EDI header"]
    else if (firstOdataLineMissing)
        ["Cannot validate Ship To — no PO line data available from P21"]
    else
        flatten([
            if (nameMatchPercentage(shipTo.name, firstOdataLine.ship2_name) < ((Mule::p('shipToValidation.lowerLimit')) as Number))
                ["ShipTo Name mismatch"]
            else
                [],
            if (addressMatchPercentage(shipTo.address1, firstOdataLine.ship2_add1) < ((Mule::p('shipToValidation.lowerLimit')) as Number))
                ["ShipTo Address1 mismatch"]
            else
                [],
            if (isMismatch(isMatch(shipTo.city, firstOdataLine.ship2_city)))
                ["ShipTo City mismatch"]
            else
                [],
            if (isMismatch(isMatch(shipTo.state, firstOdataLine.ship2_state)))
                ["ShipTo State mismatch"]
            else
                [],
            if (isMismatch(isZipMatch(shipTo.postalCode, firstOdataLine.ship2_zip)))
                ["Zip Code mismatch"]
            else
                []
        ])

var itemErrorList = flatten(valuesOf(itemErrors))
var errorCount = sizeOf(itemErrorList) + sizeOf(shipToErrors) + sizeOf(sourceErrors)
var shipToAddressMatchPercentage =
    if (shipToMissing or firstOdataLineMissing)
        0
    else
        addressMatchPercentage(shipTo.address1, firstOdataLine.ship2_add1)
var shipToNameMatchPercentage =
    if (shipToMissing or firstOdataLineMissing)
        0
    else
        nameMatchPercentage(shipTo.name, firstOdataLine.ship2_name)
---
{
    debug:
        if (DEBUG)
            {
                comparison: comparison,
                errorCount: errorCount,
                shipToAddressMatchPercentage: shipToAddressMatchPercentage,
                shipToNameMatchPercentage: shipToNameMatchPercentage
            }
        else
            null,
    isValid: errorCount == 0,
    sourceDataErrors: sourceErrors,
    validationErrors: {
        itemErrors: itemErrors,
        shipToErrors: shipToErrors,
        shipToAddressMatchPercentage: shipToAddressMatchPercentage,
        shipToNameMatchPercentage: shipToNameMatchPercentage,
        carrierErrors: [],
        externalPoErrors: [],
        customerPartErrors: []
    },
    warnings: []
}