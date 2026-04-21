%dw 2.0
output application/json
var transactionType = attributes.queryParams.transactionType
var purpose = attributes.queryParams.purpose
var businesskey =
    (attributes.queryParams.businesskey default "") splitBy "," map (trim($)) filter ($ != "") distinctBy $
var routingConfig = {
	purchaseOrder: {
		total: {
			view: Mule::p('viewNames.purchaseOrderOutbound'),
			queryParams: {
			}
		}
	},
	purchaseOrderAck: {
		validation: {
			view: Mule::p('viewNames.purchaseOrderAckInbound'),
			queryParams: {
				"\$filter": (businesskey map ("po_no eq " ++ $)) joinBy " or "
			}
		}
	},
	purchaseOrderInvoice: {
		validation: {
			view: Mule::p('viewNames.purchaseOrderInvoiceInbound'),
			queryParams: {
				"\$filter": (businesskey map ("po_no eq " ++ $)) joinBy " or "
			}
		}
	},
	purchaseOrderShipment: {
		validation: {
			view: "PURCHASE_ORDER_SHIPMENT_VALIDATION_VIEW",
			queryParams: {
				"\$filter": (businesskey map ("po_no eq " ++ $)) joinBy " or "
			}
		},
		total: {
			view: "PURCHASE_ORDER_SHIPMENT_TOTAL_VIEW",
			queryParams: {
				"\$filter": (businesskey map ("po_no eq " ++ $)) joinBy " or "
			}
		}
	}
}
var selectedConfig =
    (routingConfig[transactionType] default {
})[purpose] default {
}
---
{
	method: Mule::p('p21.request.method.OData'),
	host: Mule::p('p21.request.host'),
	port: Mule::p('p21.request.port'),
	basePath: Mule::p('p21.request.basePath.Odata'),
	path: "/" ++ (selectedConfig.view default ""),
	headers: {
		Authorization: "Bearer " ++ (vars.accessToken default ""),
		"Content-Type": "application/json"
	},
	retryMechanism: {
		"maxConcurrency": Mule::p('p21.request.reconnection.maxConcurrency.OData'),
		"retries": Mule::p('p21.request.reconnection.retries.OData')
	},
	queryParams: selectedConfig.queryParams default {
	},
	uriParams: {
	},
	body: {
	}
}