%dw 2.0
output application/json
import toBase64 from dw::core::Binaries
---
{
	"method": Mule::p('b2b-p21-sys-api.view.method'),
//	"host": Mule::p('b2b-p21-sys-api.host'),
//	"port": Mule::p('b2b-p21-sys-api.port'),
	"host":"localhost",
	"port": "8092",
	"basePath": Mule::p('b2b-p21-sys-api.basePath'),
	"path": Mule::p('b2b-p21-sys-api.view.path'),
	"headers": {
		"x-correlation-id": vars.integration.correlationId
	},
	"queryParams": {
		"transactionType": Mule::p('b2b-p21-sys-api.transactionType.salesOrder'),
		"purpose": Mule::p('b2b-p21-sys-api.purpose.total'),
		"businesskey": vars.initialPayload.b2bMessage.header.poNumber[0] default null,
		"ediRefId" : (payload[0].b2bMessage.header.partyInformation
    filter ($.qualifier == "BY"))[0].identificationCode default ""
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