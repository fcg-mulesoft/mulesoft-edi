%dw 2.0
output application/json
var transactionType = attributes.queryParams.transactionType
var purpose = attributes.queryParams.purpose
var ediRefId = attributes.queryParams.ediRefId default ""
var date_last_modified= attributes.queryParams.lastModified default ""
var businesskey =

    (attributes.queryParams.businesskey default "") splitBy "," map (trim($)) filter ($ != "") distinctBy $


var validationMode = attributes.queryParams.validationMode default "xref"
var customerId = attributes.queryParams.customerId default ""
var companyId = attributes.queryParams.companyId default "TPA"

var salesOrderValidationConfig =
    if ( validationMode == "xref" ) {
	view: "fcg_edi_xref_vw",
	filter: "edi_x_ref_id eq '" ++ ediRefId ++
                "' and company_id eq '" ++ companyId ++ "'"
}
    else if ( validationMode == "po" ) {
	view: "fcg_edi_order_vw",
	filter: "(" ++
                ((businesskey map ("po_no eq '" ++ $ ++ "'")) joinBy " or ") ++ ") and company_id eq '" ++ companyId ++ "'" ++ " and customer_id eq " ++ customerId
}
    else if ( validationMode == "customerPart" ) {
	view: "p21_view_customer_part_number",
	filter: "customer_id eq " ++ customerId ++ " and (" ++ ((businesskey map ("their_item_id eq '" ++ $ ++ "'")) joinBy " or ") ++ ")"
}
    else
        {
	view: "",
	filter: ""
}
var routingConfig = {
purchaseOrder: {
        validation: {
            view: Mule::p('viewNames.coupaPurchaseOrderPartsValidtion'),
            queryParams: {
                "\$filter": (businesskey flatMap ((item) ->
                    (item splitBy "|" filter ($ != "")) map ("their_item_id eq '" ++ $ ++ "'")
                )) joinBy " or "
            }
        },
        outbound: {
            view: Mule::p('viewNames.coupaOrderOutbound'),
            queryParams: {
                "\$filter": (businesskey map ((item) -> do {
                    var parts = item splitBy ":"
                    var poNo = parts[0] default ""
                    var companyId = parts[1] default ""
                    var customerId = parts[2] default ""
                    ---
                    "po_no eq '" ++ poNo ++ "' and company_id eq '" ++ companyId ++ "' and customer_id eq " ++ customerId
                })) joinBy " or "
            }
        },
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
				"\$filter": (businesskey map ("po_no eq " ++ $ )) joinBy " or "
			}
		}
	},
    purchaseOrderInvoice: {
		validation: {
			view: Mule::p('viewNames.purchaseOrderInvoiceInbound'),
			queryParams: {
				"\$filter": (businesskey map ("po_no eq " ++ $)) joinBy " or "
			}
		},
        outbound: {
            view: Mule::p('viewNames.coupaInvoiceOutbound'),
            queryParams: {
                "\$filter": (businesskey map ((item) -> do {
                    var parts = item splitBy ":"
                    var ediXRefId = parts[0] default ""
                    var companyId = parts[1] default ""
                    ---
                    "edi_x_ref_id eq '" ++ ediXRefId ++ "' and company_id eq '" ++ companyId ++ "'"
                })) joinBy " or "
            }
        },
        total: {
            view: Mule::p('viewNames.coupaInvoiceInbound'),
            queryParams: attributes.queryParams
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
		validation: {
			view: salesOrderValidationConfig.view,
			queryParams: {
				"\$filter": salesOrderValidationConfig.filter
			}
		}
	},
	salesOrderAck: {
		total: {
			view: Mule::p('viewNames.purchaseOrderAckOutbound'),
			queryParams: {
			}
		}
	},
	salesOrderInvoice: {
		total: {
			view: Mule::p('viewNames.purchaseOrderInvoiceOutbound'),
			queryParams: {
				"\$filter" : "date_last_modified ge  " ++ date_last_modified
			}
		}
	},
	salesOrderShipment: {
		total: {
			view: Mule::p('viewNames.purchaseOrderShipmentOutbound'),
			queryParams: {
				"\$filter": "date_last_modified ge  " ++ date_last_modified
			}
		}
	},
	emailNotification: {
		total:{
			view: Mule::p('viewNames.emailNotification'),
			queryParams: {
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
