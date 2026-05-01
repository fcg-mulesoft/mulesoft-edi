%dw 2.0
output application/json
import toBase64 from dw::core::Binaries
---
{
	"method": "POST",
	"host": Mule::p('apm.request.host'),
	"port": Mule::p('apm.request.port'),
	"basePath": Mule::p('apm.request.basePath'),
	"path": Mule::p('apm.request.path'),
	"headers": {
	},
	"queryParams": {
		"transactionType": "purchaseOrder",
		"purpose": "total",
	},
	"uriParams": {
	},
	"body": payload,
	"untilsuccessful": {
		"maxRetries": "3",
		"interval": "5000"
	}
}