%dw 2.0
output application/json
---
"errorDetails":{
  "applicationName": app.name,
  "errorCode": (if(error.errorType.identifier == 'CONNECTIVITY') p('errorCodes.connectivity') else if (error.errorType.identifier == 'NOT_FOUND')  p('errorCodes.notfound') else p('errorCodes.other')),
  "errorType": error.errorType.namespace default 'NONE' ++ ':' ++ error.errorType.identifier default 'NONE',
  "errorMessage": error.description
}