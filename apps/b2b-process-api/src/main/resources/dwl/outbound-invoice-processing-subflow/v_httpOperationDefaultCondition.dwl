%dw 2.0
output application/json
import toBase64 from dw::core::Binaries
var objectStorePayload = payload
var modifiedTime =
    if ( isEmpty(objectStorePayload) ) ((now() - |PT168H|) as String {
	format: "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
})
    else
        ((objectStorePayload as DateTime) as String {
	format: "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
})
---
{
	"method": Mule::p('b2b-p21-sys-api.view.method'),
	"host": Mule::p('b2b-p21-sys-api.host'),
	"port": Mule::p('b2b-p21-sys-api.port'),
	"basePath": Mule::p('b2b-p21-sys-api.basePath'),
	"path": Mule::p('b2b-p21-sys-api.view.path'),
	"headers": {
		"x-correlation-id": vars.initialVariables.correlationId
	},
	"queryParams": {
		"transactionType": Mule::p('b2b-p21-sys-api.transactionType.salesOrderInvoice'),
		"purpose": Mule::p('b2b-p21-sys-api.purpose.total'),
		"lastModified": "2026-06-25T15:25:33.403-04:00" //modifiedTime
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