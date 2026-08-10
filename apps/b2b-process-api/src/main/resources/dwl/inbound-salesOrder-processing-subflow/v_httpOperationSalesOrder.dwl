
%dw 2.0
output application/json
import toBase64 from dw::core::Binaries

var inputPayload = vars.initialPayload[0].b2bMessage
var header = inputPayload.header
var orderLines = inputPayload.detail.itemDetails
var salesOrderLookUpData = vars.ediXrefResponse[0]

// This contains everything we computed in the previous step
var validationData = vars.isValid

var hasHeaderErrors = validationData.validationSummary.overallStatus == "FAILED"
var headerMessage =
    if ( hasHeaderErrors ) validationData.notesPreparation.headerLevelNote
    else "Purchase Order validation completed successfully. No mismatches found."

---
{
    "method": Mule::p('b2b-p21-sys-api.transaction.method'),
    "host": Mule::p('b2b-p21-sys-api.host'),
    "port": Mule::p('b2b-p21-sys-api.port'),
    "basePath": Mule::p('b2b-p21-sys-api.basePath'),
    "path": Mule::p('b2b-p21-sys-api.transaction.path'),
    "headers": {
        "x-correlation-id": vars.integration.correlationId
    },
    "queryParams": {
        "transactionType": Mule::p('b2b-p21-sys-api.transactionType.salesOrder'),
        "processingMode": Mule::p('b2b-p21-sys-api.processingMode.direct'),
        "checkType": Mule::p('b2b-p21-sys-api.checkType.default')
    },
    "uriParams": {},
    "untilsuccessful": {
        "maxRetries": Mule::p('b2b-p21-sys-api.transaction.untilsuccessful.maxRetries'),
        "interval": Mule::p('b2b-p21-sys-api.transaction.untilsuccessful.interval')
    },
    "body": {
        UseCodeValues: true,
        IgnoreDisabled: true,
        Transactions: [{
            Status: "New",
            DataElements: [{
                Order: {
                    CustomerId: salesOrderLookUpData.customer_id,
                    CompanyId: salesOrderLookUpData.company_id,
                    LocationId: salesOrderLookUpData.preferred_location_id,
                    ShipToId: salesOrderLookUpData.ship_to_id,
                    PoNo: header.poNumber,
                    ContactId: salesOrderLookUpData.edi_default_contact_id default "",
                    Taker: salesOrderLookUpData.edi_default_taker default "MULESOFTINT",
                    Quote: "N",
                    Approved: false,
                    Notes: {
                        OrderNote: {
                            Topic: if ( hasHeaderErrors ) "HEADER LEVEL VALIDATION" else "PO VALIDATION SUCCESS",
                            Note: headerMessage,
                            NotepadClassId: "ITEMS",
                            Mandatory: if ( hasHeaderErrors ) true else false
                        }
                    },
                    Lines: {
                        OrderLine: orderLines map ((detail, index) -> do {
                            
                            var validationLine = validationData.lineComparisons[index]
                            var finalValues = validationLine.finalOrderValues
                            
                            var resolvedItemId = if (validationLine.validationSummary.isMapped) finalValues.itemId else "EDI DEFAULT ITEM"
                            
                            ---
                            {
                                // Changed to target the nested '.notes' object directly
                                (Notes: validationLine.orderLineNotes.notes) if (validationLine.orderLineNotes != null),
                                
                                LineNo: detail.lineNo,
                                ItemId: resolvedItemId,
                                ItemDesc: (detail.descriptions[0].description default "") ++ " " ++ (detail.manufacturersPartNumber default ""),
                                ExtendedDesc: detail.descriptions[0].description default "0",
                                
                                UnitQuantity: finalValues.quantity as String,
                                UnitOfMeasure: finalValues.unitOfMeasure,
                                UnitPrice: finalValues.unitPrice as String,
                                QtyOrdered: finalValues.quantity as String,
                                ExtendedPrice: finalValues.extendedPrice as String,
                                
                                SourceLocId: salesOrderLookUpData.preferred_location_id default ""
                            }
                        })
                    }
                }
            }]
        }]
    }
}
