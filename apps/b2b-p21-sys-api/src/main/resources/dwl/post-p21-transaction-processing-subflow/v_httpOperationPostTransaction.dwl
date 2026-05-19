%dw 2.0
output application/json
var transactionType = attributes.queryParams.transactionType
var checkType = attributes.queryParams.checkType default "default"
var routingConfig = {
	salesOrder: {
		"default": {
			entity: "sales/orders/",
			queryParams: {
			}
		},
		catalogPrice: {
			entity: "inventory/v2/parts/prices",
			queryParams: {
				"companyId": "TPA",
				"customerId": "1647115",
				"salesLocId": "41000",
			}
		}
	}
}
// Dynamic selection
var selectedConfig =
    routingConfig[transactionType][checkType]
        default routingConfig[transactionType]."default"
---
{
	method: "POST",
	host: "p21-dev12api.flowcontrolgroup.com",
	port: "3443",
	basePath: "/api",
	path: "/" ++ (selectedConfig.entity default ""),
	headers: {
		Authorization: "Bearer " ++ (vars.accessToken default ""),
		"Accept": "application/json"
	},
	queryParams: selectedConfig.queryParams default {
	},
	uriParams: {
	},
	body: {
	}
}