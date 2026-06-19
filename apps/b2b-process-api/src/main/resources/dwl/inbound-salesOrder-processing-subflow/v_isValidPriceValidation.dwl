%dw 2.0
output application/json

var debug = true

var ediItems =
    payload[0].b2bMessage.detail.itemDetails

var salesPricingItems =
    if (vars.salesPricing.ArrayOfItemPrice.ItemPrice is Array)
        vars.salesPricing.ArrayOfItemPrice.ItemPrice
    else
        [vars.salesPricing.ArrayOfItemPrice.ItemPrice]

var lineComparisons =
    ediItems map ((poItem, index) ->

        do {

            var matchedP21Item =
                (salesPricingItems
                    filter ((item) -> item.ItemId == poItem.buyersPartNumber))[0]

            var ediItemId = poItem.buyersPartNumber
            var p21ItemId = matchedP21Item.ItemId default null

            var ediUom = poItem.unitOfMeasurementCode
            var p21Uom = matchedP21Item.UOM default null

            var ediQty = poItem.quantityOrdered
            var p21AvailableQty =
                (matchedP21Item.QuantityAvailable default 0) as Number

            var ediUnitPrice = poItem.unitPrice
            var p21UnitPrice =
                (matchedP21Item.UnitPrice default 0) as Number

            var ediExtendedPrice =
                ediQty * ediUnitPrice

            var p21ExtendedPrice =
                (matchedP21Item.ExtendedPrice default 0) as Number

            var itemMatched =
                ediItemId == p21ItemId

            var uomMatched =
                ediUom == p21Uom

            var priceMatched =
                ediUnitPrice == p21UnitPrice

            var quantityAvailable =
                p21AvailableQty >= ediQty

            var overallStatus =
                if (
                    itemMatched
                    and uomMatched
                    and priceMatched
                    and quantityAvailable
                )
                "VALID"
                else
                "FAILED"

            var requiresP21Override =
                overallStatus == "FAILED"

            ---
            {
                lineNo: poItem.lineNo,

                validationSummary: {
                    itemMatched: itemMatched,
                    uomMatched: uomMatched,
                    priceMatched: priceMatched,
                    quantityAvailable: quantityAvailable,
                    overallStatus: overallStatus,
                    requiresP21Override: requiresP21Override
                },

                headerLevelNote:
                    if (requiresP21Override)
                        "Line " ++ poItem.lineNo ++
                        " | Item: " ++ ediItemId ++
                        " | EDI Price: " ++ (ediUnitPrice as String) ++
                        " | P21 Price: " ++ (p21UnitPrice as String)
                    else
                        null,

                orderLineNotes:
                    if (requiresP21Override)
                        {
                            lineNo: poItem.lineNo,
                            notes: {
                                OrderLineNote: {
                                    Topic: "LINE LEVEL VALIDATION",
                                    Note: "Line Item Id is incorrect or pricing mismatch found",
                                    NotepadClassId: "ITEMS",
                                    Mandatory: "Y"
                                }
                            }
                        }
                    else
                        null,

                finalOrderValues: {

                    itemId:
                        if (requiresP21Override)
                            p21ItemId
                        else
                            ediItemId,

                    quantity:
                        ediQty,

                    unitOfMeasure:
                        if (requiresP21Override)
                            p21Uom
                        else
                            ediUom,

                    unitPrice:
                        if (requiresP21Override)
                            p21UnitPrice
                        else
                            ediUnitPrice,

                    extendedPrice:
                        if (requiresP21Override)
                            p21ExtendedPrice
                        else
                            ediExtendedPrice
                }
            }
        }
    )

var failedLines =
    lineComparisons filter (
        $.validationSummary.overallStatus == "FAILED"
    )

var headerLevelNotes =
    failedLines
        map ($.headerLevelNote)
        joinBy " || "

var orderLineSection =
    failedLines
        map ($.orderLineNotes)

var validationSummary = {
    totalLines: sizeOf(lineComparisons),
    failedLines: sizeOf(failedLines),
    successfulLines:
        sizeOf(lineComparisons) - sizeOf(failedLines),

    overallStatus:
        if (sizeOf(failedLines) > 0)
            "FAILED"
        else
            "VALID"
}

---
{
    validationSummary: validationSummary,

    notesPreparation: {
        addHeaderLevelNote:
            sizeOf(failedLines) > 0,

        headerLevelNote:
            headerLevelNotes
    },

    orderLineSection: orderLineSection,

    lineComparisons: lineComparisons
}