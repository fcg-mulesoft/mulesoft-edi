%dw 2.0
output application/json
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
		"transactionType": Mule::p('b2b-p21-sys-api.transactionType.purchaseOrderInvoice'),
		"purpose": Mule::p('b2b-p21-sys-api.purpose.total'),
		"businesskey": (vars.initialPayload.Order.edixRefId default "dummy") ++ ":" ++ (vars.initialPayload.Order.PoNo default "dummy"),
		"\$filter": "date_last_modified ge " ++ (vars.vmPayload.watermark) ++ " and corp_id eq 481272" ,
		"\$orderby": "date_last_modified asc",
		"\$count": true
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