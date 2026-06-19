%dw 2.0
output application/json
---
{
	status: "SUCCESS",
	poNumber: payload.b2bMessage.header.sellerOrderNumber,
	partnerId: payload.b2bMessage.header.receiverId,
	transmissionId: vars.transmissionId
}