%dw 2.0
output application/json
---
if(!isEmpty(vars.errorResponse))
vars.errorResponse
else
"errorDetails":{
  "applicationName": app.name,
  "errorCode": error.exception.errorDetails.errorCode default (if(error.errorType.identifier == 'CONNECTIVITY') p('errorCodes.connectivity') else p('errorCodes.other')),
  "errorType": error.exception.errorDetails.errorType default error.errorType.namespace default 'NONE' ++ ':' ++ error.errorType.identifier default 'NONE',
  "errorMessage": error.exception.errorDetails.errorMessage default error.description
}