%dw 2.0
output application/json
import toBase64 from dw::core::Binaries
var objectStorePayload = vars.invoiceTimeStamp
var modifiedTime =
    if (isEmpty(objectStorePayload))
        (((now() - |PT168H|) >> "UTC") as String {
            format: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        })
    else
        (((objectStorePayload as DateTime) >> "UTC") as String {
            format: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
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
		"lastModified": modifiedTime
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