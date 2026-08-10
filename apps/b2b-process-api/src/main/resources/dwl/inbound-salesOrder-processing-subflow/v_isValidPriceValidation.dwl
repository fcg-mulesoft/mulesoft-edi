
%dw 2.0
output application/json

// 1. Build Lookup Maps
fun getCustomerItemMap(response) =
    (response default []) reduce ((item, acc = {}) ->
        acc ++ { (item.their_item_id default ""): item.our_item_id }
    )

// Use groupBy instead of a simple mapObject because a single ItemId could have multiple pricing records (e.g. for different UOMs)
fun getSalesPricingMap(response) =
    (response default []) groupBy ($.ItemId default "")

// 2. Validation Helper
fun validateItem(ediUom, ediUnitPrice, ediQty, p21Items) = do {
    // Attempt to find the specific UOM, otherwise fallback to the first returned item
    var p21Item = (p21Items filter ((i) -> upper(i.UOM default "") == ediUom))[0] default p21Items[0]
    var p21Uom = upper(p21Item.UOM default "")
    var p21Qty = (p21Item.QuantityAvailable default 0) as Number
    var p21Price = (p21Item.UnitPrice default 0) as Number
    
    // Use tolerance for decimal comparison
    var priceDiff = abs(ediUnitPrice - p21Price)

    var failureReason =
        if (p21Item == null) "ITEM_NOT_FOUND_P21"
        else if (ediUom != p21Uom) "UOM_MISMATCH"
        else if (priceDiff > 0.01) "PRICE_MISMATCH"
        else if (ediQty > p21Qty) "INSUFFICIENT_QUANTITY"
        else "VALID"

    ---
    {
        p21Item: p21Item,
        p21Uom: p21Uom,
        p21Qty: p21Qty,
        p21Price: p21Price,
        failureReason: failureReason,
        overallStatus: if (failureReason == "VALID") "VALID" else "FAILED"
    }
}

// 3. Notes Helpers
fun generateHeaderNote(lineNo, ediItemId, ourItemId, ediUom, ediUnitPrice, ediQty, p21Uom, p21Price, p21Qty, failureReason) =
    if (failureReason == "MAPPING_NOT_FOUND")
        "Line " ++ lineNo ++ " - Item " ++ ediItemId ++ " mapping missing"
    else if (failureReason == "ITEM_NOT_FOUND_P21")
        "Line " ++ lineNo ++ " - Item " ++ (ourItemId default "") ++ " not present in P21"
    else if (failureReason == "UOM_MISMATCH")
        "Line " ++ lineNo ++ " - UOM mismatch (EDI: " ++ ediUom ++ ", P21: " ++ p21Uom ++ ")"
    else if (failureReason == "PRICE_MISMATCH")
        "Line " ++ lineNo ++ " - Price mismatch (EDI: \$" ++ (ediUnitPrice as Number {format: "0.00"}) ++ ", P21: \$" ++ (p21Price as Number {format: "0.00"}) ++ ")"
    else if (failureReason == "INSUFFICIENT_QUANTITY")
        "Line " ++ lineNo ++ " - Insufficient quantity (EDI: " ++ ediQty ++ ", P21: " ++ p21Qty ++ ")"
    else null

fun generateLineNote(ediItemId, ourItemId, ediUom, ediUnitPrice, ediQty, p21Uom, p21Price, p21Qty, failureReason) =
    if (failureReason == "MAPPING_NOT_FOUND")
        "Customer Item Mapping missing for " ++ ediItemId
    else if (failureReason == "ITEM_NOT_FOUND_P21")
        "Item " ++ (ourItemId default "") ++ " not present in P21"
    else if (failureReason == "UOM_MISMATCH")
        "Unit of Measure mismatch. EDI: " ++ ediUom ++ ", P21: " ++ p21Uom
    else if (failureReason == "PRICE_MISMATCH")
        "Price mismatch. EDI: \$" ++ (ediUnitPrice as Number {format: "0.00"}) ++ ", P21: \$" ++ (p21Price as Number {format: "0.00"})
    else if (failureReason == "INSUFFICIENT_QUANTITY")
        "Insufficient quantity. EDI: " ++ ediQty ++ ", P21: " ++ p21Qty
    else null

// 4. Final Values Helper
fun getFinalValues(isMapped, ourItemId, ediItemId, ediQty, ediUom, ediUnitPrice, p21Uom, p21Price, requiresOverride, itemExistsInP21) = do {
    var finalQty = ediQty
    var finalUnitPrice = if (requiresOverride and itemExistsInP21) p21Price else ediUnitPrice
    var finalUom = if (requiresOverride and itemExistsInP21) p21Uom else ediUom
    
    ---
    {
        itemId: if (isMapped) ourItemId else ediItemId,
        quantity: finalQty,
        unitOfMeasure: finalUom,
        unitPrice: finalUnitPrice as Number {format: "0.00"},
        extendedPrice: (finalQty * finalUnitPrice) as Number {format: "0.00"}
    }
}


// ====================================================================
// Main Execution
// ====================================================================

var customerItemMap = getCustomerItemMap(vars.customerItemValidationResponse)

// Safely extract the SalesPricing array, flattening it in case the .* operator returns nested arrays
var salesPricingMap = getSalesPricingMap(flatten(vars.salesPricing.ArrayOfItemPrice.*ItemPrice default []))

var ediItems = payload[0].b2bMessage.detail.itemDetails default []

var lineComparisons = ediItems map ((poItem) -> do {
    var ediItemId = poItem.buyersPartNumber default ""
    var ediUom = upper(poItem.unitOfMeasurementCode default "")
    var ediQty = (poItem.quantityOrdered default 0) as Number
    var ediUnitPrice = (poItem.unitPrice default 0) as Number
    
    var ourItemId = customerItemMap[ediItemId]
    var isMapped = ourItemId != null
    
    var p21Items = if (isMapped) salesPricingMap[ourItemId] default [] else []
    var itemExistsInP21 = sizeOf(p21Items) > 0
    
    var validationResult = 
        if (!isMapped)
            { failureReason: "MAPPING_NOT_FOUND", overallStatus: "FAILED", p21Item: null, p21Uom: "", p21Qty: 0, p21Price: 0 }
        else if (!itemExistsInP21)
            { failureReason: "ITEM_NOT_FOUND_P21", overallStatus: "FAILED", p21Item: null, p21Uom: "", p21Qty: 0, p21Price: 0 }
        else
            validateItem(ediUom, ediUnitPrice, ediQty, p21Items)
            
    // Override business logic: currently overrides on price or UOM mismatch. Adjust if required.
    var requiresOverride = (validationResult.failureReason == "PRICE_MISMATCH" or validationResult.failureReason == "UOM_MISMATCH")

    ---
    {
        lineNo: poItem.lineNo,
        validationSummary: {
            isMapped: isMapped,
            itemExistsInP21: itemExistsInP21,
            uomMatched: itemExistsInP21 and (ediUom == validationResult.p21Uom),
            priceMatched: itemExistsInP21 and (abs(ediUnitPrice - validationResult.p21Price) <= 0.01),
            quantityAvailable: itemExistsInP21 and (validationResult.p21Qty >= ediQty),
            failureReason: validationResult.failureReason,
            overallStatus: validationResult.overallStatus,
            requiresP21Override: requiresOverride
        },
        headerLevelNote: generateHeaderNote(poItem.lineNo, ediItemId, ourItemId, ediUom, ediUnitPrice, ediQty, validationResult.p21Uom, validationResult.p21Price, validationResult.p21Qty, validationResult.failureReason),
        orderLineNotes: if (validationResult.overallStatus == "FAILED") {
            lineNo: poItem.lineNo,
            notes: {
                OrderLineNote: {
                    Topic: "LINE LEVEL VALIDATION",
                    Note: generateLineNote(ediItemId, ourItemId, ediUom, ediUnitPrice, ediQty, validationResult.p21Uom, validationResult.p21Price, validationResult.p21Qty, validationResult.failureReason),
                    NotepadClassId: "ITEMS",
                    Mandatory: "Y"
                }
            }
        } else null,
        finalOrderValues: getFinalValues(isMapped, ourItemId, ediItemId, ediQty, ediUom, ediUnitPrice, validationResult.p21Uom, validationResult.p21Price, requiresOverride, itemExistsInP21)
    }
})

var failedLines = lineComparisons filter ($.validationSummary.overallStatus == "FAILED")

---
{
    validationSummary: {
        totalLines: sizeOf(lineComparisons),
        failedLines: sizeOf(failedLines),
        successfulLines: sizeOf(lineComparisons) - sizeOf(failedLines),
        overallStatus: if (isEmpty(failedLines)) "VALID" else "FAILED"
    },
    notesPreparation: {
        addHeaderLevelNote: !isEmpty(failedLines),
        headerLevelNote: (failedLines map $.headerLevelNote) joinBy "\n"
    },
    orderLineSection: failedLines map $.orderLineNotes filter ($ != null),
    lineComparisons: lineComparisons
}
