%dw 2.0
output application/json
import toBase64 from dw::core::Binaries
---
{
	"method": Mule::p('b2b-p21-sys-api.view.method'),
	"host": Mule::p('b2b-p21-sys-api.host'),
	"port": Mule::p('b2b-p21-sys-api.port'),
	"basePath": Mule::p('b2b-p21-sys-api.basePath'),
	"path": Mule::p('b2b-p21-sys-api.view.path'),
	"headers": {
		"x-correlation-id": correlationId
	},
	"queryParams": {
		"transactionType": Mule::p('b2b-p21-sys-api.transactionType.emailNotification'),
		"purpose": Mule::p('b2b-p21-sys-api.purpose.total')
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