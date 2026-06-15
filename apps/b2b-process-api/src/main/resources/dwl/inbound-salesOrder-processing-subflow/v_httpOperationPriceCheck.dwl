%dw 2.0
output application/json
import toBase64 from dw::core::Binaries
var inputPayload = vars.initialPayload[0]
var customerItemId = vars.customerItemValidationResponse
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
		"checkType": "catalogPrice",
		"customerId": vars.ediXrefResponse.customer_id[0],
		"companyId": vars.ediXrefResponse.company_id[0],
		"salesLocId": vars.ediXrefResponse.preferred_location_id[0]
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
		Transactions: [{
			Status: "New",
			DataElements: [{
				ArrayOfItemPriceInfo: {
					ItemPriceInfo: inputPayload.b2bMessage.detail.itemDetails map (item) -> do {
						var itemLookup =
                (customerItemId filter ((x) -> x.their_item_id == item.buyersPartNumber))[0]
						---
						{
							ItemId: itemLookup.our_item_id default "",
							SourceLocId:  vars.ediXrefResponse.preferred_location_id[0],
							CustomerPartNo: item.buyersPartNumber,
							UnitQuantity: item.quantityOrdered,
							UnitSize: 1,
							UOM: item.unitOfMeasurementCode
						}
					}
				}
			}]
		}]
	}
}