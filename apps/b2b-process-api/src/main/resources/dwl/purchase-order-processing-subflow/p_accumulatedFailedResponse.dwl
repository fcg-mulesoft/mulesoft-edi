%dw 2.0
output application/json
---
{
	status: "FAILED",
	partnerId: payload.B2BMessage.Header.receiverId,
	poNumber: payload.B2BMessage.Header.purchaseOrderNumber default "UNKNOWN",
	error: error.description,
	
}