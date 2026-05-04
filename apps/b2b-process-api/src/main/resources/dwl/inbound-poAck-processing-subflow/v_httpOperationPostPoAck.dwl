%dw 2.0
output application/json
import toBase64 from dw::core::Binaries
---
{
    "method": "POST",
    "host": Mule::p('b2b-p21-sys-api.host'),
    "port": Mule::p('b2b-p21-sys-api.port'),
    "basePath": Mule::p('b2b-p21-sys-api.basePath'),
    "path": Mule::p('b2b-p21-sys-api.transaction.path'),
	"headers": {
		"x-correlation-id": vars.integration.correlationId
	},
	"queryParams":{
		"transactionType": "purchaseOrderAck",
    },
    "uriParams": {
    },
    "untilsuccessful":{
    	"maxRetries": "5",
    	"interval": "5000"
    },
    "body": vars.p21poAck
}