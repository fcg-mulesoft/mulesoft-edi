%dw 2.0
output application/json
import toBase64 from dw::core::Binaries
---
{
	"method": "GET",
	"host": Mule::p('b2b-p21-sys-api.host'),
	"port": Mule::p('b2b-p21-sys-api.port'),
	"basePath": Mule::p('b2b-p21-sys-api.basePath'),
	"path": Mule::p('b2b-p21-sys-api.view.path'),
	"headers": {
		"x-correlation-id": vars.initialVariables.correlationId
	},
	"queryParams": {
		"transactionType": "purchaseOrder",
		"purpose": "total",
	},
	"uriParams": {
	},
	"body": {
	},
	"untilsuccessful": {
		"maxRetries": "3",
		"interval": "5000"
	}
}