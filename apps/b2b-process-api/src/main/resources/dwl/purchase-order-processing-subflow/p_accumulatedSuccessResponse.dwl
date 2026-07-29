%dw 2.0
output application/json
---
{
	status: "SUCCESS",
	poNumber: payload.b2bMessage.header.purchaseOrderNumber,
	partnerId: payload.b2bMessage.header.receiverId default "Partner Id Not Found",
	transmissionId: vars.transmissionId
}