%dw 2.0
output application/json
var explictHandlerCodes = p('explicitcodes')
---
{
	"correlationId": correlationId default uuid(),
	"statusCode": (if ( explictHandlerCodes contains vars.httpStatus ) (vars.httpStatus) else (error.errorMessage.payload.statusCode default vars.httpStatus)) default 500,
	"statusMessage": (if ( explictHandlerCodes contains vars.httpStatus ) ((error.errorType.namespace ++ ":" ++ error.errorType.identifier)) else (error.errorMessage.payload.statusMessage)) default (error.errorType.namespace ++ ":" ++ error.errorType.identifier),
	"description": (if ( explictHandlerCodes contains vars.httpStatus ) (if((error.errorType.namespace ++ ":" ++ error.errorType.identifier) contains "RETRY_EXHAUSTED")(error.description) else error.detailedDescription) else (error.errorMessage.payload.description)) default (if((error.errorType.namespace ++ ":" ++ error.errorType.identifier) contains "RETRY_EXHAUSTED")(error.description) else error.detailedDescription),
	"timestamp": (if(explictHandlerCodes contains vars.httpStatus) ((now() as String {format : "yyyy/MM/dd HH:mm:ss"}) ++ " UTC") else (error.errorMessage.payload.errorDateTime)) default ((now() as String {format : "yyyy/MM/dd HH:mm:ss"}) ++ " UTC"),
    "notificationRequired": if (Mule::p('api.name') contains "sys-")(false) else (if ( (explictHandlerCodes contains vars.httpStatus) and (!(isEmpty(error.errorMessage) or (error.errorMessage.attributes.reasonPhrase ~= "BAD GATEWAY" or error.errorMessage.attributes.reasonPhrase ~= "NOT FOUND")))) (false) else if ( (explictHandlerCodes contains vars.httpStatus) and isEmpty(error.errorMessage) ) (true) else if ( !(explictHandlerCodes contains vars.httpStatus) and (!isEmpty(error.errorMessage.payload.notificationRequired )) ) (!(error.errorMessage.payload.notificationRequired))  else true)
}
