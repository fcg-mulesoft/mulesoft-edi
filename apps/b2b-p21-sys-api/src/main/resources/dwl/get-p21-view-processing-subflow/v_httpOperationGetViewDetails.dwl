%dw 2.0
output application/json
var transactionType = attributes.queryParams.transactionType
var purpose = attributes.queryParams.purpose
var ediRefId = attributes.queryParams.ediRefId default ""
var date_last_modified= attributes.queryParams.lastModified default ""
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
				"\$filter": (businesskey map ("po_no eq '" ++ $ ++ "'")) joinBy " or "
			}
		}
	},
	purchaseOrderInvoice: {
		validation: {
			view: Mule::p('viewNames.purchaseOrderInvoiceInbound'),
			queryParams: {
				"\$filter": (businesskey map ("po_no eq '" ++ $ ++ "'")) joinBy " or "
			}
		}
	},
	purchaseOrderShipment: {
		validation: {
			view: Mule::p('viewNames.purchaseOrderShipmentValidation'),
			queryParams: {
				"\$filter": (businesskey map ("po_no eq '" ++ $ ++ "'")) joinBy " or "
			}
		},
		total: {
			view: Mule::p('viewNames.purchaseOrderShipmentTotal'),
			queryParams: {
				"\$filter": (businesskey map ("po_no eq '" ++ $ ++ "'")) joinBy " or "
			}
		}
	},
	salesOrder: {
		total: {
			view: "fcg_edi_xref_vw",
			queryParams: {
				"\$filter": "edi_x_ref_id eq '" ++ ediRefId ++

                    "' and ((" ++

                    ((businesskey map ("po_no eq '" ++ $ ++ "'")) joinBy " or ") ++ ") or po_no eq null or po_no eq ' ')"
			}
		}
	},
	salesOrderAck: {
		total: {
			view: Mule::p('viewNames.purchaseorderAckOutbound'),
			queryParams: {
			}
		}
	},
	salesOrderInvoice: {
		total: {
			view: Mule::p('viewNames.purchaseorderInvoiceOutbound'),
			queryParams: {
				"\$filter" : "date_last_modified ge  " ++ date_last_modified
			}
		}
	},
	salesOrderShipment: {
		total: {
			view: ,
			queryParams: {
				"\$filter" : "date_last_modified ge  " ++ date_last_modified
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
	queryParams: selectedConfig.queryParams default {
	},
	uriParams: {
	},
	body: {
	}
}
 