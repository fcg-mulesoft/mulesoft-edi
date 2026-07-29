%dw 2.0
output application/json
---
{
	status: "SUCCESS",
	invoiceNumber: payload.b2bMessage.header.invoiceNumber,
	partnerId: payload.b2bMessage.header.senderId,
	transmissionId: vars.transmissionId
}