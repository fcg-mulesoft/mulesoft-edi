%dw 2.0
output application/json
import toBase64 from dw::core::Binaries

var inputPayload = vars.initialPayload[0].b2bMessage

var header =
    inputPayload.header

var orderLines =
    inputPayload.detail.itemDetails

var salesPricing =
    vars.salesPricing.ArrayOfItemPrice.ItemPrice

var salesOrderLookUpData =
    vars.salesOrderLookUpData[0]

var validationData =
    vars.isValid

var pricingLines =
    if (salesPricing is Array)
        salesPricing
    else
        [salesPricing]

var hasHeaderErrors =
    validationData.validationSummary.overallStatus == "FAILED"

var headerMessage =
    if (hasHeaderErrors)
        validationData.notesPreparation.headerLevelNote
    else
        "Purchase Order validation completed successfully. No mismatches found."

---
{
	"method": Mule::p('b2b-p21-sys-api.transaction.method'),
//	"host": Mule::p('b2b-p21-sys-api.host'),
//	"port": Mule::p('b2b-p21-sys-api.port'),
	"host": "localhost",
	"port": "8092",
	"basePath": Mule::p('b2b-p21-sys-api.basePath'),
	"path": Mule::p('b2b-p21-sys-api.transaction.path'),
	"headers": {
		"x-correlation-id": vars.integration.correlationId
	},
	"queryParams": {
		"transactionType": Mule::p('b2b-p21-sys-api.transactionType.salesOrder'),
		"processingMode": "direct",
		"checkType": "default",
		
	},
	"uriParams": {
	},
	"untilsuccessful": {
		"maxRetries": Mule::p('b2b-p21-sys-api.transaction.untilsuccessful.maxRetries'),
		"interval": Mule::p('b2b-p21-sys-api.transaction.untilsuccessful.interval')
	},
	"body": {
  UseCodeValues: true,

  IgnoreDisabled: true,

  Transactions: [
    {
      Status: "New",

      DataElements: [
        {
          Order: {

            CustomerId:
              salesOrderLookUpData.customer_id,

            CompanyId:
              salesOrderLookUpData.company_id,

            LocationId:
              pricingLines[0].LocationId default "",

            ShipToId:
              salesOrderLookUpData.ship_to_id,

            PoNo:
              header.poNumber,

            ContactId:
              salesOrderLookUpData.edi_default_contact_id default "",

            Taker:
              salesOrderLookUpData.edi_default_contact_id
              default "MULESOFTINT",

            Quote: "N",

            Approved: "false",

            Notes: {
              OrderNote: {
                Topic:
                  if (hasHeaderErrors)
                    "HEADER LEVEL VALIDATION"
                  else
                    "PO VALIDATION SUCCESS",

                Note:
                  headerMessage,

                NotepadClassId: "ITEMS",

                Mandatory:
                  if (hasHeaderErrors)
                    "true"
                  else
                    "false"
              }
            },

            Lines: {
              OrderLine:

                orderLines map ((detail, index) -> do {

                  var matchedPricing =
                    pricingLines filter (
                      ($.ItemId default "")
                      ==
                      (detail.buyersPartNumber default "")
                    )

                  var pricing =
                    if (sizeOf(matchedPricing) > 0)
                      matchedPricing[0]
                    else
                      {}

                  var matchedLineNote =
                    (
                      validationData.lineComparisons
                      filter (
                        (($.lineNo default "") as String)
                        ==
                        ((detail.lineNo default "") as String)
                      )
                    )[0] default null

                  var hasLineError =
                    matchedLineNote != null
                    and
                    matchedLineNote.orderLineNotes != null

                  ---
                  {

                    (Notes:
                      matchedLineNote.orderLineNotes.notes)
                      if (hasLineError),

                    LineNo:
                      detail.lineNo,

                    ItemId:
                      pricing.ItemId default "",

                    ItemDesc:
                      (detail.descriptions[0].description default "")
                      ++ " "
                      ++
                      (detail.manufacturersPartNumber default ""),

                    ExtendedDesc:
                      detail.descriptions[0].description default "",

                    UnitQuantity:
                      detail.quantityOrdered as String,

                    UnitOfMeasure:
                      pricing.UOM default "",

                    UnitPrice:
                      pricing.UnitPrice default "",

                    QtyOrdered:
                      detail.quantityOrdered as String,

                    ExtendedPrice:
                      pricing.ExtendedPrice default "",

                    SourceLocId:
                      pricing.LocationId default ""
                  }
                })
            }
          }
        }
      ]
    }
  ]
}
}