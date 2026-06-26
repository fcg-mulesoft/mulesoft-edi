%dw 2.0
output application/json
---
{
	"correlationId": (correlationId default uuid()),
	"statusCode": vars.httpStatus,
	"statusMessage": (error.errorType.namespace ++ ":" ++ error.errorType.identifier),
	"description": if((error.errorType.namespace ++ ":" ++ error.errorType.identifier) contains "RETRY_EXHAUSTED")(error.description) else error.detailedDescription,
	"timestamp": (((now() >> "UTC")  as String {
		format : "yyyy/MM/dd HH:mm:ss"
	}) ++ " UTC"),
	notificationRequired: true
}