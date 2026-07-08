%dw 2.0
output application/json
---
if(error.errorType.identifier == "BAD_REQUEST") (400) else
if(error.errorType.identifier == "NOT_FOUND" and !isEmpty(error.errorMessage.payload))(404) else
if(error.errorType.identifier == "NOT_FOUND" and isEmpty(error.errorMessage.payload))(504) else
if(error.errorType.identifier == "METHOD_NOT_ALLOWED") (405) else
if(error.errorType.identifier == "UNAUTHORIZED" or error.errorType.identifier == "FORBIDDEN") (401) else
if(error.errorType.identifier == "GATEWAY_TIMEOUT") (504) else
if(error.errorType.identifier == "BAD_GATEWAY") (502) else
if (!isEmpty(error.errorMessage.attributes.statusCode default ""))(error.errorMessage.attributes.statusCode) else
if (!isEmpty(attributes.statusCode))(attributes.statusCode) else
(500)