%dw 2.0
output application/json
import toBase64 from dw::core::Binaries
---
{
	"method": Mule::p('apm.request.method'),
	"host": Mule::p('apm.request.host'),
	"port": Mule::p('apm.request.port'),
	"basePath": Mule::p('apm.request.basePath'),
	"path": Mule::p('apm.request.poAck'),
	"headers": {
	},
	"queryParams": {
		
	},
	"uriParams": {
	},
	"body": payload,
	"untilsuccessful": {
		"maxRetries": Mule::p('apm.request.untilsuccessful.maxRetries'),
		"interval": Mule::p('apm.request.untilsuccessful.interval')
	}
}