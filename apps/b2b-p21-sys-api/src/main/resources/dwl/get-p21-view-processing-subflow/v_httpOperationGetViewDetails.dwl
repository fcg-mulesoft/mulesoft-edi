%dw 2.0
output application/json
var transactionType = attributes.queryParams.transactionType
var purpose = attributes.queryParams.purpose

var businesskey =
    (attributes.queryParams.businesskey default "") splitBy "," map (trim($)) filter ($ != "") distinctBy $
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
    (routingConfig[transactionType] default {})[purpose] default {}
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
    queryParams: selectedConfig.queryParams default {},
    uriParams: {},
    body: {}
}