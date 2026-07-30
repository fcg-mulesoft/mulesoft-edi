%dw 2.0
output application/json
import toBase64 from dw::core::Binaries

---
{
    "method": Mule::p('b2b-p21-sys-api.view.method'),
    "host": Mule::p('b2b-p21-sys-api.host'),
    "port": Mule::p('b2b-p21-sys-api.port'),
    "basePath": Mule::p('b2b-p21-sys-api.basePath'),
    "path": Mule::p('b2b-p21-sys-api.view.path'),
    "headers": {
        "x-correlation-id": vars.initialVariables.correlationId
    },
    "queryParams":
        {
            "transactionType": Mule::p('b2b-p21-sys-api.transactionType.salesOrderInvoice'),
            "purpose": Mule::p('b2b-p21-sys-api.purpose.validation'),
            "startTime": (((attributes.queryParams.startTime) as DateTime) >> "UTC") as String {format: "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"},
            "endTime": (((attributes.queryParams.endTime) as DateTime) >> "UTC") as String {format: "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"}
        }
        ++ (
            if (!isEmpty(attributes.queryParams.partnerName default ""))
            { "partnerName": attributes.queryParams.partnerName }
            else
            {}
        )
        ++ (
            if (!isEmpty(attributes.queryParams.businessKey default ""))
            { "businessKey": attributes.queryParams.businessKey }
            else
            {}
        ),
    "uriParams": {},
    "body": {},
    "untilsuccessful": {
        "maxRetries": Mule::p('b2b-p21-sys-api.view.untilsuccessful.maxRetries'),
        "interval": Mule::p('b2b-p21-sys-api.view.untilsuccessful.interval')
    }
}