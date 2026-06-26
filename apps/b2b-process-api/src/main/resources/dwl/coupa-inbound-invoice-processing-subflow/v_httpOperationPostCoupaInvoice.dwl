%dw 2.0
output application/json
---
{
    "method": Mule::p('b2b-inbound-partner-mgmt-api.coupa-invoice.method'),
    "host": Mule::p('b2b-inbound-partner-mgmt-api.host'),
    "port": Mule::p('b2b-inbound-partner-mgmt-api.port'),
    "basePath": Mule::p('b2b-inbound-partner-mgmt-api.basePath'),
    "path": Mule::p('b2b-inbound-partner-mgmt-api.coupa-invoice.path'),
    "headers": {
        "x-correlation-id": correlationId
    },
    "queryParams": {
    },
    "uriParams": {
    },
    "body": {
      value: [payload]
    },
    "untilsuccessful": {
        "maxRetries": Mule::p('b2b-inbound-partner-mgmt-api.coupa-invoice.untilsuccessful.maxRetries'),
        "interval": Mule::p('b2b-inbound-partner-mgmt-api.coupa-invoice.untilsuccessful.interval')
    }
}