%dw 2.0
output application/json
---
{
	status: "SUCCESS",
	poNumber: payload.B2BMessage.Header.purchaseOrderNumber,
	partnerId: payload.B2BMessage.Header.receiverId default "Partner Id Not Found",
	transmissionId: vars.transmissionId
}