%dw 2.0
output application/json
import toBase64 from dw::core::Binaries
---
{
	"method": Mule::p('b2b-p21-sys-api.view.method'),
//	"host": Mule::p('b2b-p21-sys-api.host'),
//	"port": Mule::p('b2b-p21-sys-api.port'),
	"host": "localhost",
	"port": "8092",
	"basePath": Mule::p('b2b-p21-sys-api.basePath'),
	"path": Mule::p('b2b-p21-sys-api.view.path'),
	"headers": {
		"x-correlation-id": vars.integration.correlationId
	},
	"queryParams": {
		"transactionType": Mule::p('b2b-p21-sys-api.transactionType.salesOrder'),
		"purpose": Mule::p('b2b-p21-sys-api.purpose.validation'),
		"businesskey": vars.initialPayload.b2bMessage.header.poNumber[0] default null,
		"validationMode": "po",
		"customerId": vars.ediXrefResponse.customer_id[0],
		"companyId": vars.ediXrefResponse.company_id[0],
	},
	"uriParams": {
	},
	"body": {
	},
	"untilsuccessful": {
		"maxRetries": Mule::p('b2b-p21-sys-api.view.untilsuccessful.maxRetries'),
		"interval": Mule::p('b2b-p21-sys-api.view.untilsuccessful.interval')
	}
}