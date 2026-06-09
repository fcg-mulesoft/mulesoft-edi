%dw 2.0
output application/json
import toBase64 from dw::core::Binaries
var inputPayload = vars.initialPayload[0]
var viewData = vars.salesOrderLookUpData[0]
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
		"companyId": viewData.company_id,
		"customerId": viewData.customer_id,
		"salesLocId": viewData.preferred_location_id
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
					ItemPriceInfo: inputPayload.b2bMessage.detail.itemDetails map (item) -> {
						ItemId: item.buyersPartNumber,
						SourceLocId: viewData.preferred_location_id as String,
						CustomerPartNo: item.buyersPartNumber,
						UnitQuantity: item.quantityOrdered,
						UnitSize: 1,
						UOM: item.unitOfMeasurementCode
					}
				}
			}]
		}]
	}
}