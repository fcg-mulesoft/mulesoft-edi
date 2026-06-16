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
		"businesskey": (vars.initialPayload.Order.edixRefId default "") ++ ":" ++ (vars.initialPayload.Order.PoNo default ""),
		"\$filter": "invoice_no in ('" ++ (vars.invoiceList joinBy "','") ++ "')",
		"\$top": 1000
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