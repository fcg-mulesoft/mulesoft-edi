%dw 2.0
output application/json
---
if((error.errorType.namespace ++ ":" ++ error.errorType.identifier) == "APIKIT:BAD_REQUEST") (400) else
if((error.errorType.namespace ++ ":" ++ error.errorType.identifier) == "APIKIT:NOT_FOUND") (404) else
if((error.errorType.namespace ++ ":" ++ error.errorType.identifier) == "APIKIT:METHOD_NOT_ALLOWED") (405) else
if((error.errorType.namespace ++ ":" ++ error.errorType.identifier) == "APIKIT:NOT_ACCEPTABLE") (406) else
if((error.errorType.namespace ++ ":" ++ error.errorType.identifier) == "APIKIT:UNSUPPORTED_MEDIA_TYPE") (415) else (500)