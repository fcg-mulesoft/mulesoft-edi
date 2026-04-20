%dw 2.0
output application/json
var transactionType = attributes.queryParams.transactionType
var serviceMapping = {
	purchaseOrder: Mule::p('serviceNames.purchaseOrder'),
	purchaseOrderAck: Mule::p('serviceNames.purchaseOrderAck'),
	purchaseOrderInvoice: Mule::p('serviceNames.purchaseOrderInvoice'),
	purchaseOrderShipment: Mule::p('serviceNames.purchaseOrderShipment'),
}
var serviceName = serviceMapping[transactionType]
---
{
	Name: serviceName
} ++ payload