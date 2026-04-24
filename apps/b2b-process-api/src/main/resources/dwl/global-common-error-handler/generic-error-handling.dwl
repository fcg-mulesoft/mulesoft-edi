%dw 2.0
import * from dw::core::Strings
output text/plain

fun safe(v, d="N/A") =
    if (v == null or (v is String and trim(v) == "")) d else v

var errResp     = vars.errorResponse     default {}
var sysInfo     = vars.systemInformation default {}
var integration = vars.integration       default {}

var cdm       = (vars.initialPayload default [])[0].b2bMessage default {}
var cdmHeader = cdm.header default {}

var isP21Failed =
    (error.errorType.namespace  default "") == "CUSTOM" and
    (error.errorType.identifier default "") == "P21_FAILED"

var isValidationFlow = vars.isValid != null and not isP21Failed

var errNs      = if (isValidationFlow) "CUSTOM"   else (error.errorType.namespace  default "UNKNOWN")
var errId      = if (isValidationFlow) "VALIDATION_ERROR" else (error.errorType.identifier default "ERROR")
var errDesc    = if (isValidationFlow) "Validation failed while processing transaction."
                 else (error.detailedDescription default error.description default "Unexpected error")

var suppressed = if (isValidationFlow) null else (error.suppressedErrors[0] default null)
var suppNs     = suppressed.errorType.namespace  default ""
var suppId     = suppressed.errorType.identifier default ""

var sourceSystem =
    if (isValidationFlow) "APM"
    else safe(integration.source, "UNKNOWN")

var targetSystem =
    if (isValidationFlow) "P21"
    else safe(integration.target, "UNKNOWN")

var flowDirection =
    if (lower(sourceSystem) == "apm") "INBOUND"
    else                              "OUTBOUND"

var categoryNs = if (suppressed != null and suppNs != "") suppNs else errNs
var categoryId = if (suppressed != null and suppId != "") suppId else errId

var errorTypeValue =
    if (isValidationFlow)
        "CUSTOM:VALIDATION_ERROR"
    else if (suppressed != null and (suppNs != "" or suppId != ""))
        (if (suppNs != "") suppNs else "UNKNOWN") ++ ":" ++
        (if (suppId != "") suppId else "ERROR")
    else if (!isEmpty(errResp.statusMessage default ""))
        errResp.statusMessage as String
    else
        errNs ++ ":" ++ errId

var errorCategory =
    if (isValidationFlow)
        "VALIDATION"
    else if (categoryNs == "CUSTOM" and categoryId == "P21_FAILED")
        "P21_ERROR"
    else if (categoryId == "BAD_REQUEST" or categoryId == "SCHEMA_NOT_HONOURED"
          or categoryId == "INVALID_INPUT" or categoryId == "UNRECOGNIZED_FIELD"
          or categoryId == "MISSING_REQUIRED_FIELD" or categoryId == "PARSE_ERROR"
          or categoryNs == "VALIDATION" or categoryNs == "JSON"
          or categoryNs == "XML" or categoryNs == "CSV")
        "VALIDATION"
    else if (categoryNs == "APIKIT" and suppressed == null)
        "APIKIT"
    else if (categoryId == "UNAUTHORIZED" or categoryId == "FORBIDDEN"
          or categoryId == "AUTHENTICATION_FAILED" or categoryId == "INVALID_TOKEN"
          or categoryId == "TOKEN_EXPIRED" or categoryId == "ACCESS_DENIED"
          or categoryNs == "OAUTH2" or categoryNs == "JWT"
          or (categoryNs == "MULE" and categoryId == "SECURITY"))
        "SECURITY"
    else if (categoryId == "TIMEOUT" or categoryId == "GATEWAY_TIMEOUT"
          or categoryId == "BAD_GATEWAY" or categoryId == "CONNECTIVITY"
          or categoryId == "CONNECTION_TIMEOUT" or categoryId == "READ_TIMEOUT"
          or categoryId == "WRITE_TIMEOUT" or categoryId == "RETRY_EXHAUSTED"
          or categoryId == "SERVICE_UNAVAILABLE" or categoryId == "REMOTELY_CLOSED"
          or categoryId == "SSL_ERROR")
        "CONNECTIVITY"
    else if (categoryId == "NOT_FOUND" or categoryId == "METHOD_NOT_ALLOWED"
          or categoryId == "NOT_ACCEPTABLE" or categoryId == "UNSUPPORTED_MEDIA_TYPE"
          or categoryId == "CONFLICT" or categoryId == "GONE"
          or categoryId == "TOO_MANY_REQUESTS")
        "CLIENT_ERROR"
    else if (categoryId == "TRANSFORMATION" or categoryId == "EXPRESSION"
          or categoryId == "COERCION" or categoryId == "SCRIPTING_FAILED"
          or (categoryNs == "MULE" and (categoryId == "TRANSFORMATION" or categoryId == "EXPRESSION")))
        "TRANSFORMATION"
    else if (categoryId == "ROUTING" or categoryId == "COMPOSITE_ROUTING"
          or categoryId == "FLOW_NOT_FOUND")
        "ROUTING"
    else
        "GENERIC"

var errorTitle =
    if      (errorCategory == "P21_ERROR")       "P21 Integration Error"
    else if (errorCategory == "APIKIT")          "API Error"
    else if (errorCategory == "SECURITY")        "Security Error"
    else if (errorCategory == "VALIDATION")      "Validation Error"
    else if (errorCategory == "CONNECTIVITY")    "Connectivity Error"
    else if (errorCategory == "CLIENT_ERROR")    "Client Error"
    else if (errorCategory == "TRANSFORMATION")  "Transformation Error"
    else if (errorCategory == "ROUTING")         "Routing Error"
    else                                         "System Error"

var bannerColor =
    if      (errorCategory == "P21_ERROR")       "#0369a1"
    else if (errorCategory == "SECURITY")        "#f59e0b"
    else if (errorCategory == "VALIDATION")      "#f59e0b"
    else if (errorCategory == "CLIENT_ERROR")    "#f97316"
    else if (errorCategory == "CONNECTIVITY")    "#6366f1"
    else if (errorCategory == "TRANSFORMATION")  "#06b6d4"
    else if (errorCategory == "ROUTING")         "#0ea5e9"
    else                                         "#ef4444"

var ve = vars.isValid.validationErrors default {}

var msgPoNumber = safe(cdmHeader.poNumber as String,
                    safe(vars.initialPayload[0].b2bMessage.header.poNumber as String, "N/A"))

var senderKey = safe(cdmHeader.senderId, safe(integration.source, "N/A")) as String

var msgVendorId =
    if (p('partner.' ++ senderKey) != null)
        p('partner.' ++ senderKey)
    else
        senderKey

var itemRows =
    flatten(
        (ve.itemErrors default {}) pluck ((value, key) ->
            (value default []) map (err) ->
                "<tr style='background:#fee2e2;color:#b91c1c;'>"
                ++ "<td style='padding:8px;border:1px solid #ddd;'>Item (" ++ key ++ ")</td>"
                ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ err ++ "</td>"
                ++ "</tr>"
        )
    )

var carrierRows =
    (ve.carrierErrors default []) map (e) ->
        "<tr style='background:#fee2e2;color:#b91c1c;'>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>Carrier</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ e ++ "</td></tr>"

var externalPoRows =
    (ve.externalPoErrors default []) map (e) ->
        "<tr style='background:#fee2e2;color:#b91c1c;'>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>External PO</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ e ++ "</td></tr>"

var customerPartRows =
    (ve.customerPartErrors default []) map (e) ->
        "<tr style='background:#fee2e2;color:#b91c1c;'>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>Customer Part</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ e ++ "</td></tr>"

var totalRows =
    (ve.totalErrors default []) map (e) ->
        "<tr style='background:#fee2e2;color:#b91c1c;'>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>Total</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ e ++ "</td></tr>"

var shipToRows =
    (ve.shipToErrors default []) map (e) ->
        "<tr style='background:#fee2e2;color:#b91c1c;'>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>Ship To</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ e ++ "</td></tr>"

var allRows =
    itemRows ++ carrierRows ++ externalPoRows ++ customerPartRows ++ totalRows ++ shipToRows

var validationHtml =
    if (sizeOf(allRows) > 0)
        "<table style='width:100%;border-collapse:collapse;margin-top:10px;'>"
        ++ "<tr style='background:#fecaca;'>"
        ++ "<th style='padding:8px;border:1px solid #ddd;'>Type</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;'>Error</th>"
        ++ "</tr>"
        ++ (allRows joinBy "")
        ++ "</table>"
    else
        "Validation failed but no detailed errors available."

var corrId =
    if (isValidationFlow) safe(cdmHeader.transmissionId, uuid())
    else (errResp.correlationId default correlationId default uuid())

var data = {
    flowDirection: flowDirection,
    documentType: safe(integration."integration-type",
                     safe(vars.systemInformation."integration-type",
                         safe(cdmHeader.documentType, "API"))),
    appName: p('api.name') default "Mule Application",
    transactionType: safe(integration."integration-type",
                         safe(vars.systemInformation."integration-type",
                             safe(cdmHeader.documentType, "API"))),
    environment: upper(safe(sysInfo.env, p('mule.env'))),
    flowName: safe(vars.flowName, "Global Error Handler"),
    route: sourceSystem ++ " → Mule → " ++ targetSystem,
    partnerName:
        if (p('partner.' ++ senderKey) != null)
            p('partner.' ++ senderKey)
        else
            sourceSystem,
    errorTitle: errorTitle,
    bannerColor: bannerColor,
    errorType: errorTypeValue,
    errorCategory: errorCategory,
    status: "FAILED",
    errorCode: if (isValidationFlow) "VALIDATION_ERROR" else errId,
    message:
        "Error occurred for PO " ++ msgPoNumber ++ " (Vendor: " ++ msgVendorId ++ ").",
    errorDescription: validationHtml,
    transmissionId: if (isValidationFlow) safe(cdmHeader.transmissionId)
                    else (vars.initialPayload[0].b2bMessage.header.transmissionId default corrId),
    keyLabel: if (isValidationFlow) "PO Number" else "Correlation ID",
    key: if (isValidationFlow) safe(cdmHeader.poNumber) else corrId,
    timestamp: errResp.timestamp default (now() as String {format: "yyyy-MM-dd HH:mm:ss"})
}

var template =
    readUrl("classpath://templates/error-template.html", "text/plain")
---
template replace /\$\{(\w+)\}/ with ((m) ->
    (data[m[1]] as String) default ""
)