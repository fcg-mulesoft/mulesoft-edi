%dw 2.0
output application/xml
import toBase64 from dw::core::Binaries
---
{
	"method": Mule::p('b2b-p21-sys-api.transaction.method'),
	"host": Mule::p('b2b-p21-sys-api.host'),
	"port": Mule::p('b2b-p21-sys-api.port'),
	"basePath": Mule::p('b2b-p21-sys-api.basePath'),
	"path": Mule::p('b2b-p21-sys-api.transaction.path'),
	"headers": {
		"x-correlation-id": vars.integration.correlationId,
		"Content-Type": "application/xml"
	},
	"queryParams": {
		"transactionType": Mule::p('b2b-p21-sys-api.transactionType.partsPrice'),
		"companyId": payload.value[0].company_id,
		"customerId": payload.value[0].customer_id,
		"salesLocId": payload.value[0].preferred_location_id
	},
	"uriParams": {
	},
	"untilsuccessful": {
		"maxRetries": Mule::p('b2b-p21-sys-api.transaction.untilsuccessful.maxRetries'),
		"interval": Mule::p('b2b-p21-sys-api.transaction.untilsuccessful.interval')
	},
	"body": vars.p21PartsPrice
}