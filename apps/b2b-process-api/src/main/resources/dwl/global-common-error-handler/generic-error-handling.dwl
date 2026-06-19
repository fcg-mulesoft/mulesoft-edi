%dw 2.0
import * from dw::core::Strings
output text/plain

fun safe(v, d="N/A") =
    if (v == null or (v is String and trim(v) == "")) d else v

var errResp     = vars.errorResponse     default {}
var sysInfo     = vars.systemInformation default {}
var integration = vars.integration  default vars.initialVariables     default {}

var cdm       = (vars.initialPayload default [])[0].b2bMessage default {}
var cdmHeader = cdm.header default {}

var rawErrNs  = error.errorType.namespace   default "UNKNOWN"
var rawErrId  = error.errorType.identifier  default "ERROR"
var rawSup    = error.suppressedErrors[0]   default null
var rawSupId  = rawSup.errorType.identifier default ""
var rawSupNs  = rawSup.errorType.namespace  default ""

var isP21Failed =
    rawErrNs == "CUSTOM" and rawErrId == "P21_FAILED"

var isRetryExhausted =
    rawErrId == "RETRY_EXHAUSTED"
    or rawSupId == "RETRY_EXHAUSTED"
    or rawErrId == "TIMEOUT"
    or rawErrId == "GATEWAY_TIMEOUT"
    or rawErrId == "CONNECTION_TIMEOUT"
    or rawSupId == "TIMEOUT"
    or rawSupId == "GATEWAY_TIMEOUT"

var isValidationFlow =
    vars.isValid != null
    and not isP21Failed
    and not isRetryExhausted

var errNs   = if (isValidationFlow) "CUSTOM"           else rawErrNs
var errId   = if (isValidationFlow) "VALIDATION_ERROR" else rawErrId
var errDesc = if (isValidationFlow) "Validation failed while processing transaction."
              else (error.detailedDescription default error.description default "Unexpected error")

var suppressed = if (isValidationFlow) null else (rawSup)
var suppNs     = if (isValidationFlow) "" else rawSupNs
var suppId     = if (isValidationFlow) "" else rawSupId

var sourceSystem =
    if (isValidationFlow) "APM"
    else safe(integration.source, "P21")

var targetSystem =
    if (isValidationFlow) "P21"
    else safe(integration.target, "APM")

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
    else if (categoryId == "BAD_REQUEST"             or categoryId == "SCHEMA_NOT_HONOURED"
          or categoryId == "INVALID_INPUT"           or categoryId == "UNRECOGNIZED_FIELD"
          or categoryId == "MISSING_REQUIRED_FIELD"  or categoryId == "PARSE_ERROR"
          or categoryNs == "VALIDATION"              or categoryNs == "JSON"
          or categoryNs == "XML"                     or categoryNs == "CSV")
        "VALIDATION"
    else if (categoryNs == "APIKIT" and suppressed == null)
        "APIKIT"
    else if (categoryId == "UNAUTHORIZED"          or categoryId == "FORBIDDEN"
          or categoryId == "AUTHENTICATION_FAILED" or categoryId == "INVALID_TOKEN"
          or categoryId == "TOKEN_EXPIRED"          or categoryId == "ACCESS_DENIED"
          or categoryNs == "OAUTH2"                 or categoryNs == "JWT"
          or (categoryNs == "MULE"                  and categoryId == "SECURITY"))
        "SECURITY"
    else if (categoryId == "TIMEOUT"                or categoryId == "GATEWAY_TIMEOUT"
          or categoryId == "BAD_GATEWAY"            or categoryId == "CONNECTIVITY"
          or categoryId == "CONNECTION_TIMEOUT"     or categoryId == "READ_TIMEOUT"
          or categoryId == "WRITE_TIMEOUT"          or categoryId == "RETRY_EXHAUSTED"
          or categoryId == "SERVICE_UNAVAILABLE"    or categoryId == "REMOTELY_CLOSED"
          or categoryId == "SSL_ERROR")
        "CONNECTIVITY"
    else if (categoryId == "NOT_FOUND"              or categoryId == "METHOD_NOT_ALLOWED"
          or categoryId == "NOT_ACCEPTABLE"         or categoryId == "UNSUPPORTED_MEDIA_TYPE"
          or categoryId == "CONFLICT"               or categoryId == "GONE"
          or categoryId == "TOO_MANY_REQUESTS")
        "CLIENT_ERROR"
    else if (categoryId == "TRANSFORMATION"         or categoryId == "EXPRESSION"
          or categoryId == "COERCION"               or categoryId == "SCRIPTING_FAILED"
          or (categoryNs == "MULE" and (categoryId == "TRANSFORMATION" or categoryId == "EXPRESSION")))
        "TRANSFORMATION"
    else if (categoryId == "ROUTING"                or categoryId == "COMPOSITE_ROUTING"
          or categoryId == "FLOW_NOT_FOUND")
        "ROUTING"
    else
        "GENERIC"

var errorTitle =
    if      (errorCategory == "P21_ERROR")      "P21 Integration Error"
    else if (errorCategory == "APIKIT")         "API Error"
    else if (errorCategory == "SECURITY")       "Security Error"
    else if (errorCategory == "VALIDATION")     "Validation Error"
    else if (errorCategory == "CONNECTIVITY")   "Connectivity Error"
    else if (errorCategory == "CLIENT_ERROR")   "Client Error"
    else if (errorCategory == "TRANSFORMATION") "Transformation Error"
    else if (errorCategory == "ROUTING")        "Routing Error"
    else                                        "System Error"

var bannerColor =
    if      (errorCategory == "P21_ERROR")      "#0369a1"
    else if (errorCategory == "SECURITY")       "#f59e0b"
    else if (errorCategory == "VALIDATION")     "#f59e0b"
    else if (errorCategory == "CLIENT_ERROR")   "#f97316"
    else if (errorCategory == "CONNECTIVITY")   "#6366f1"
    else if (errorCategory == "TRANSFORMATION") "#06b6d4"
    else if (errorCategory == "ROUTING")        "#0ea5e9"
    else                                        "#ef4444"

var ve = vars.isValid.validationErrors default {}

var msgPoNumber = safe(cdmHeader.poNumber default "" as String,
                    safe(vars.initialPayload[0].b2bMessage.header.poNumber default "" as String, 
                    	safe(vars.initialPayload.Order.PoNo default "" as String,"N/A")
                    ))

var senderKey = safe(cdmHeader.senderId, safe(integration.source, "N/A")) as String

var msgVendorId =
    if (p('partner.inbound.' ++ senderKey) != null) p('partner.inbound.' ++ senderKey)
    else if (p('partner.outbound.' ++ senderKey) != null) p('partner.outbound.' ++ senderKey)
    else "N/A"

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

var duplicateRows =
    (ve.duplicatePo default []) map (e) ->
        "<tr style='background:#fee2e2;color:#b91c1c;'>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>Duplicate</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ e ++ "</td></tr>"

var ediXrefId =
    (ve.ediXrefId default []) map (e) ->
        "<tr style='background:#fee2e2;color:#b91c1c;'>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>Invalid EDI Refrence ID</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ e ++ "</td></tr>"
		
var allRows =
    itemRows ++ carrierRows ++ externalPoRows ++ customerPartRows ++ totalRows ++ shipToRows ++ duplicateRows ++ ediXrefId
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

var errorResolution =
    if (errorCategory == "VALIDATION")
        if (isValidationFlow)
            "The information received does not match what is expected in the system."
            ++ "\n  1. Review the file or data that was sent and check for incorrect or missing values."
            ++ "\n  2. Compare the sent data against the expected format and correct any mismatches."
            ++ "\n  3. Resend the corrected file once all values have been verified."
            ++ "\n\n  If you are unsure which values are incorrect, contact your EDI coordinator for guidance."
        else if (categoryId == "BAD_REQUEST" or categoryId == "SCHEMA_NOT_HONOURED")
            "The data submitted did not match the expected format or structure."
            ++ "\n  1. This is a data issue — review the payload sent from " ++ sourceSystem ++ " for incorrect values, wrong data types, or fields outside allowed values."
            ++ "\n  2. Compare the submitted data against the API schema to identify non-conforming fields."
            ++ "\n  3. Correct the identified fields in " ++ sourceSystem ++ " and resubmit."
            ++ "\n  4. Contact the integration support team with the Correlation ID if the schema is unclear."
            ++ "\n\n  Resubmission is safe once the payload has been corrected."
        else if (categoryId == "MISSING_REQUIRED_FIELD")
            "A required field was not included in the data that was sent."
            ++ "\n  1. Check which field is missing — it will be identified in the error description below."
            ++ "\n  2. Ensure " ++ sourceSystem ++ " is populating all mandatory fields before sending."
            ++ "\n  3. Correct the data and resubmit once all required fields are present."
            ++ "\n\n  Do not resubmit until the missing field has been populated."
        else if (categoryId == "PARSE_ERROR")
            "The system was unable to read or interpret the data that was sent."
            ++ "\n  1. The file or message may be corrupted, incomplete, or in the wrong format."
            ++ "\n  2. Verify that the Content-Type matches the actual format (e.g. JSON, XML)."
            ++ "\n  3. Check for special characters, encoding problems, or truncated content."
            ++ "\n  4. Correct the source data in " ++ sourceSystem ++ " and resubmit."
        else
            "The data sent did not pass the required checks before it could be processed."
            ++ "\n  1. Review the error details below to identify which field or value caused the issue."
            ++ "\n  2. Correct the identified field(s) in " ++ sourceSystem ++ " before resending."
            ++ "\n  3. Contact the integration support team with the Correlation ID if the error is unclear."
            ++ "\n\n  Do not resend the data until the issue has been corrected."

    else if (errorCategory == "P21_ERROR")
        "The transaction was sent to P21 successfully but P21 was unable to process it."
        ++ "\n  1. Note the PO Number and error message shown in the details below."
        ++ "\n  2. Log into P21 and look up the Purchase Order using the PO Number listed."
        ++ "\n  3. Check whether the order is in the correct status and all required fields are filled in."
        ++ "\n  4. If the order looks correct in P21, contact your P21 administrator to investigate further."
        ++ "\n  5. Once the issue is resolved in P21, the transaction can be resubmitted."
        ++ "\n\n  Do not resubmit until you have confirmed whether the transaction was partially saved in P21."

    else if (errorCategory == "CONNECTIVITY")
        do {
            var base  = "The integration was unable to establish a connection with " ++ "P21" ++ "."
            var steps =
                if (categoryId == "RETRY_EXHAUSTED")
                    "\n  1. The system attempted to reach " ++ "P21" ++ " multiple times but all attempts failed."
                    ++ "\n  2. " ++ "P21" ++ " may be down or unreachable — check whether it is currently available."
                    ++ "\n  3. Do not retry manually — contact the IT support team to report the outage."
                    ++ "\n  4. The support team will investigate and reprocess the transaction once " ++ "P21" ++ " is back online."
                else if (categoryId == "TIMEOUT" or categoryId == "CONNECTION_TIMEOUT" or categoryId == "GATEWAY_TIMEOUT")
                    "\n  1. " ++ "P21" ++ " did not respond in time — it may be under heavy load or temporarily unavailable."
                    ++ "\n  2. Wait a few minutes and try resubmitting the transaction."
                    ++ "\n  3. If the timeout keeps happening, contact the IT support team — do not keep retrying manually."
                else if (categoryId == "SSL_ERROR")
                    "\n  1. A security certificate issue prevented the connection to " ++ "P21" ++ "."
                    ++ "\n  2. This is not a data issue — contact the IT support team immediately with the Correlation ID."
                    ++ "\n  3. Do not retry until the certificate issue has been confirmed as resolved."
                else if (categoryId == "SERVICE_UNAVAILABLE")
                    "\n  1. " ++ "P21" ++ " is currently unavailable — it may be undergoing maintenance."
                    ++ "\n  2. Wait until " ++ "P21" ++ " is confirmed back online before resubmitting."
                    ++ "\n  3. Contact the support team if the service remains unavailable for more than 30 minutes."
                else
                    "\n  1. Check whether " ++ "P21" ++ " is currently available and accessible."
                    ++ "\n  2. If " ++ "P21" ++ " is under maintenance or experiencing an outage, wait until it is back online."
                    ++ "\n  3. Try resubmitting the transaction after a few minutes."
                    ++ "\n  4. If the problem persists, contact the IT support team with the Correlation ID."
            ---
            base ++ steps
            ++ "\n\n  No data was lost — the transaction can be safely resubmitted once connectivity is restored."
        }

    else if (errorCategory == "SECURITY")
        do {
            var base  = "The system was unable to authenticate or gain access to " ++ targetSystem ++ "."
            var steps =
                if (categoryId == "UNAUTHORIZED" or categoryId == "AUTHENTICATION_FAILED")
                    "\n  1. The login credentials used to connect to " ++ targetSystem ++ " are invalid or have expired."
                    ++ "\n  2. Contact your IT or integration support team — do not attempt to fix credentials yourself."
                    ++ "\n  3. Provide the Correlation ID from the error details when raising the issue."
                else if (categoryId == "FORBIDDEN" or categoryId == "ACCESS_DENIED")
                    "\n  1. The system connected but does not have permission to perform this action in " ++ targetSystem ++ "."
                    ++ "\n  2. This is a permissions issue — contact the IT support team."
                    ++ "\n  3. Do not retry — the transaction will keep failing until permissions are corrected."
                else if (categoryId == "TOKEN_EXPIRED" or categoryId == "INVALID_TOKEN")
                    "\n  1. The security token used to connect to " ++ targetSystem ++ " has expired or is invalid."
                    ++ "\n  2. Contact the integration support team — the token needs to be refreshed or reissued."
                    ++ "\n  3. Provide the Correlation ID when raising the issue."
                else
                    "\n  1. This is typically caused by expired or incorrect login credentials."
                    ++ "\n  2. Contact your IT or integration support team — do not attempt to fix credentials yourself."
                    ++ "\n  3. Provide the Correlation ID from the error details when raising the issue."
            ---
            base ++ steps
            ++ "\n\n  Do not retry until the access issue has been resolved by the support team."
        }

    else if (errorCategory == "CLIENT_ERROR")
        do {
            var base  = targetSystem ++ " could not complete the request as submitted."
            var steps =
                if (categoryId == "NOT_FOUND")
                    "\n  1. The record being referenced does not exist in " ++ targetSystem ++ "."
                    ++ "\n  2. Verify the PO Number or vendor ID is correct."
                    ++ "\n  3. Check whether the record was recently deleted or archived in " ++ targetSystem ++ "."
                    ++ "\n  4. Correct the reference and resubmit, or contact the support team if the record should exist."
                else if (categoryId == "CONFLICT")
                    "\n  1. A duplicate or conflicting record was detected in " ++ targetSystem ++ "."
                    ++ "\n  2. Check whether this transaction has already been processed — look up the PO in " ++ targetSystem ++ "."
                    ++ "\n  3. Contact the support team with the Correlation ID if you are unsure."
                else if (categoryId == "TOO_MANY_REQUESTS")
                    "\n  1. Too many requests were sent to " ++ targetSystem ++ " in a short period."
                    ++ "\n  2. Wait a few minutes before resubmitting."
                    ++ "\n  3. Contact the integration support team if this occurs frequently."
                else
                    "\n  1. Review the error message below for details on what went wrong."
                    ++ "\n  2. Check whether the record or order being referenced still exists in " ++ targetSystem ++ "."
                    ++ "\n  3. Contact the support team with the Correlation ID if the issue is unclear."
            ---
            base ++ steps
        }

    else if (errorCategory == "TRANSFORMATION")
        do {
            var base  = "The system encountered an issue while preparing the data for processing."
            var steps =
                if (categoryId == "COERCION")
                    "\n  1. A field value could not be converted to the expected data type (e.g. text found where a number was expected)."
                    ++ "\n  2. Check the source data in " ++ sourceSystem ++ " for the affected field and ensure it contains a valid value."
                    ++ "\n  3. Contact the integration support team with the Correlation ID if the source data looks correct."
                else
                    "\n  1. This is an internal mapping issue — end users do not need to take action on the data itself."
                    ++ "\n  2. Contact the integration support team and provide the Correlation ID shown below."
                    ++ "\n  3. The support team will investigate the mapping and redeploy a fix if required."
            ---
            base ++ steps
            ++ "\n\n  Hold off on resubmitting until the support team confirms the mapping has been corrected."
        }

    else if (errorCategory == "APIKIT")
        "The request was not formatted correctly and could not be accepted by the system."
        ++ "\n  1. This is usually caused by a system or integration configuration issue, not a data entry error."
        ++ "\n  2. Contact the integration support team with the Correlation ID shown below."
        ++ "\n  3. Do not retry until the support team has identified and resolved the issue."

    else if (errorCategory == "ROUTING")
        "The transaction could not be directed to the correct processing step."
        ++ "\n  1. This is an internal routing issue — no action is required on the data itself."
        ++ "\n  2. Contact the integration support team with the Correlation ID shown below."
        ++ "\n  3. The support team will investigate and reprocess the transaction if needed."

    else
        "An unexpected issue occurred while processing this transaction."
        ++ "\n  1. No immediate action is required on your end."
        ++ "\n  2. Contact the integration support team and provide the Correlation ID shown below."
        ++ "\n  3. The support team will investigate the root cause and advise on next steps."
        ++ "\n\n  Please do not resubmit the transaction until you have heard back from the support team."

var errorDescFull =
    if (isValidationFlow)
        validationHtml
    else
        (errResp.description default errDesc default "Unexpected error") as String
        ++ "\n\nCorrelation ID: " ++ (errResp.correlationId default correlationId default uuid())
        ++ "\nHTTP Status:    " ++ ((errResp.statusCode default vars.httpStatus default 500) as String)
        ++ "\nStatus Message: " ++ (errResp.statusMessage default errorTypeValue)
        ++ "\nTimestamp:      " ++ (errResp.timestamp default (now() as String {format: "yyyy-MM-dd HH:mm:ss"}))

var corrId =
    if (isValidationFlow) safe(cdmHeader.transmissionId, uuid())
    else (errResp.correlationId default correlationId default uuid())

var data = {
    flowDirection:   flowDirection,
    documentType:    safe(integration."integration-type",
                         safe(vars.systemInformation."integration-type",
                             safe(cdmHeader.documentType, "API"))),
    appName:         p('api.name') default "Mule Application",
    transactionType: safe(integration."integration-type",
                         safe(vars.systemInformation."integration-type",
                             safe(cdmHeader.documentType, "API"))),
    environment:     upper(safe(sysInfo.env, p('mule.env'))),
    route:           sourceSystem ++ " → Mule → " ++ targetSystem,
    errorTitle:      errorTitle,
    bannerColor:     bannerColor,
    errorType:       errorTypeValue,
    errorCategory:   errorCategory,
    status:          "FAILED",
    errorCode:       if (isValidationFlow) "VALIDATION_ERROR" else errId,
  	message:
        if (isValidationFlow)
            "Validation failed while processing transaction for PO "
            ++ msgPoNumber ++ " (Vendor: " ++ msgVendorId ++ ")."
        else if (errorCategory == "P21_ERROR")
            "P21 rejected the transaction for PO " ++ msgPoNumber
            ++ " (Vendor: " ++ msgVendorId ++ ") on the "
            ++ sourceSystem ++ " → " ++ "P21" ++ " route."
        else if (errorCategory == "CONNECTIVITY")
            "Failed to reach " ++ "P21" ++ " while processing PO "
            ++ msgPoNumber ++ " (Vendor: " ++ msgVendorId ++ "). "
            ++ "Error: " ++ categoryId ++ "."
        else if (errorCategory == "SECURITY")
            "Access denied while connecting to " ++ "P21"
            ++ " for PO " ++ msgPoNumber ++ " (Vendor: " ++ msgVendorId ++ "). "
            ++ "Reason: " ++ categoryId ++ "."
        else if (errorCategory == "VALIDATION")
            "Request payload for PO " ++ msgPoNumber
            ++ " (Vendor: " ++ msgVendorId ++ ") failed validation. "
            ++ "Reason: " ++ categoryId ++ "."
        else if (errorCategory == "TRANSFORMATION")
            "Data mapping failed while processing PO " ++ msgPoNumber
            ++ " (Vendor: " ++ msgVendorId ++ ") on the "
            ++ sourceSystem ++ " → " ++ "P21" ++ " route. "
            ++ "Reason: " ++ categoryId ++ "."
        else if (errorCategory == "CLIENT_ERROR")
                    "P21" ++ " returned an error for PO " ++ msgPoNumber
            ++ " (Vendor: " ++ msgVendorId ++ "). "
            ++ "Reason: " ++ categoryId ++ "."
        else if (errorCategory == "APIKIT")
            "Invalid request received from " ++ sourceSystem
            ++ " for PO " ++ msgPoNumber ++ ". "
            ++ "Reason: " ++ categoryId ++ "."
        else if (errorCategory == "ROUTING")
            "Message could not be routed for PO " ++ msgPoNumber
            ++ " (Vendor: " ++ msgVendorId ++ ") on the "
            ++ sourceSystem ++ " → " ++ targetSystem ++ " route. "
            ++ "Reason: " ++ categoryId ++ "."
        else
            "An error occurred on the " ++ sourceSystem ++ " → " ++ targetSystem
            ++ " route for PO " ++ msgPoNumber
            ++ " Vendor: " ++ msgVendorId ++ " "
            ++ "Error: " ++ categoryId ++ ".",
    errorResolution:  errorResolution,
    errorDescription: errorDescFull,
    vendorName: msgVendorId,
    businessKey: "PO " ++ msgPoNumber,
    transmissionId:   if (isValidationFlow) safe(cdmHeader.transmissionId)
                      else (vars.initialPayload[0].b2bMessage.header.transmissionId default "N/A"),
    companyName: (vars.purchaseOrderData.value.company_no[0] default "N/A"),
    keyLabel:        "Correlation ID",
    key:             correlationId default uuid(),
    timestamp:        errResp.timestamp default (now() as String {format: "yyyy-MM-dd HH:mm:ss"})
}

var template =
    readUrl("classpath://templates/error-template.html", "text/plain")
---
template replace /\$\{(\w+)\}/ with ((m) ->
    (data[m[1]] as String) default ""
)