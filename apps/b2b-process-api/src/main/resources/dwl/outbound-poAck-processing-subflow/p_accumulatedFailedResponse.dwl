%dw 2.0
output application/json
---
{
	status: "FAILED",
	partnerId: payload.b2bMessage.header.receiverId,
	poNumber: payload.b2bMessage.header.sellerOrderNumber default "UNKNOWN",
	error: error.description,
	statusCode: vars.httpStatus,
	errorType: error.errorType.parentErrorType.identifier,
	statusMessage: (error.errorType.namespace ++ ":" ++ error.errorType.identifier),
	description:
		if ((error.errorType.namespace ++ ":" ++ error.errorType.identifier) contains "RETRY_EXHAUSTED")
			error.description
		else
			error.detailedDescription
}