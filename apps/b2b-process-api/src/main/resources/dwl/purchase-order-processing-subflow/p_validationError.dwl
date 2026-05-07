%dw 2.0
import * from dw::core::Strings
output text/plain

fun safe(v, d="N/A") =
    if (v == null or (v is String and trim(v) == "")) d else v
fun present(v)          = v != null and (v as String) != ""
fun resolvePartner(pId) =
    if (p('partner.outbound.' ++ pId) != null)
        p('partner.outbound.' ++ pId)
    else
        pId

var partner      = if (payload is String) read(payload, "application/json") else payload

var partnerId    = resolvePartner(safe(partner.partnerId as String, "UNKNOWN"))
var partnerErrors = partner.errors default []

var poNumbers =
    (partnerErrors map ((e) -> e.poNo as String)) filter present($)

var poSegment =
    if (sizeOf(poNumbers) > 0) ("PO(s) " ++ (poNumbers joinBy ", ")) else "N/A"

fun extractHttpCode(desc) =
    do {
        var d     = (desc default "") as String
        var match = d find /[( ](\d{3})[) .]/
        ---
        if (!isEmpty(match) and !isEmpty(match[0]))
            (d[(match[0][0] + 1) to (match[0][0] + 3)] as Number default 0)
        else 0
    }

fun resolveErrorType(apmType, httpCode) =
    if      (httpCode == 401)                   "UNAUTHORIZED"
    else if (httpCode == 403)                   "FORBIDDEN"
    else if (httpCode == 404)                   "NOT_FOUND"
    else if (httpCode == 400)                   "BAD_REQUEST"
    else if (httpCode >= 500)                   "SERVER_ERROR"
    else if (upper(apmType) == "CONNECTIVITY")  "CONNECTIVITY"
    else if (upper(apmType) == "TIMEOUT")       "TIMEOUT"
    else if (upper(apmType) == "VALIDATION")    "VALIDATION"
    else if (upper(apmType) != "")              upper(apmType)
    else                                        "UNKNOWN"

fun buildErrorConfig(resolvedType, descStr) =
    if      (resolvedType == "CONNECTIVITY") {
        title:       "APM Connection Failure",
        bannerColor: "#dc2626",
        errorCode:   "APM_CONNECTION_ERROR",
        category:    "CONNECTIVITY",
        message:     "850 transmission failed with error type [CONNECTIVITY] while sending to APM. " ++ descStr,
        resolution:  "The 850 transmission failed because Mule could not connect to the APM endpoint."
                     ++ "\n  1. Verify the APM endpoint URL and port in the Mule connector configuration."
                     ++ "\n  2. Check DNS resolution and firewall rules between Mule and APM."
                     ++ "\n  3. Confirm the APM service is running and accepting inbound connections."
                     ++ "\n  4. Review VPN, proxy, or network peering configuration."
                     ++ "\n  5. Once connectivity is restored, resubmit: " ++ poSegment
                     ++ "\n\n  Do NOT resubmit until the connection issue is fully resolved."
    }
    else if (resolvedType == "NOT_FOUND")    {
        title:       "APM Endpoint Not Found (404)",
        bannerColor: "#f59e0b",
        errorCode:   "APM_ENDPOINT_NOT_FOUND",
        category:    "CONFIGURATION",
        message:     "850 transmission failed with error type [NOT_FOUND] — the APM endpoint returned HTTP 404. " ++ descStr,
        resolution:  "The 850 transmission failed because the APM endpoint URL returned 404."
                     ++ "\n  1. Verify the APM endpoint URL configured in Mule matches the deployed APM route exactly."
                     ++ "\n  2. Confirm with the APM team that the route is deployed and active in the correct environment."
                     ++ "\n  3. Check if the APM application was redeployed or the route was renamed/moved."
                     ++ "\n  4. Update the Mule endpoint URL property and redeploy if misconfigured."
                     ++ "\n  5. Once the correct URL is confirmed, resubmit: " ++ poSegment
                     ++ "\n\n  Do NOT resubmit until the APM route is confirmed reachable."
    }
    else if (resolvedType == "TIMEOUT")      {
        title:       "APM Request Timeout",
        bannerColor: "#f97316",
        errorCode:   "APM_TIMEOUT_ERROR",
        category:    "TIMEOUT",
        message:     "850 transmission failed with error type [TIMEOUT] — the APM endpoint did not respond within the allowed time. " ++ descStr,
        resolution:  "The 850 transmission timed out waiting for APM."
                     ++ "\n  1. Check APM service health and response times via the APM monitoring dashboard."
                     ++ "\n  2. Increase the HTTP request timeout in the Mule connector if APM is under load."
                     ++ "\n  3. Confirm no payload or transformation bottleneck is causing delays on the APM side."
                     ++ "\n  4. Coordinate with the APM team to investigate slow processing for: " ++ poSegment
                     ++ "\n  5. Once stable, resubmit the affected transactions."
                     ++ "\n\n  Do NOT resubmit until the APM team confirms the service is stable."
    }
    else if (resolvedType == "UNAUTHORIZED") {
        title:       "APM Authentication Failure (401)",
        bannerColor: "#7c3aed",
        errorCode:   "APM_UNAUTHORIZED",
        category:    "SECURITY",
        message:     "850 transmission failed with error type [UNAUTHORIZED] — APM rejected the request due to missing or invalid credentials (HTTP 401). " ++ descStr,
        resolution:  "The 850 transmission failed because APM returned 401 Unauthorized."
                     ++ "\n  1. Verify the API key, client ID/secret, or bearer token configured in Mule is current."
                     ++ "\n  2. Check if APM credentials have expired or been rotated recently."
                     ++ "\n  3. Confirm the correct authentication scheme is being used (Basic, OAuth2, API Key, etc.)."
                     ++ "\n  4. Update credentials in the Mule secure properties vault and redeploy."
                     ++ "\n  5. Once credentials are corrected, resubmit: " ++ poSegment
                     ++ "\n\n  Do NOT resubmit until valid credentials are in place."
    }
    else if (resolvedType == "FORBIDDEN")    {
        title:       "APM Access Denied (403)",
        bannerColor: "#7c3aed",
        errorCode:   "APM_FORBIDDEN",
        category:    "SECURITY",
        message:     "850 transmission failed with error type [FORBIDDEN] — APM denied access (HTTP 403). " ++ descStr,
        resolution:  "The 850 transmission failed because APM returned 403 Forbidden."
                     ++ "\n  1. Confirm the Mule service account has the correct role/scope in APM."
                     ++ "\n  2. Check if an IP whitelist or policy is blocking the Mule runtime IP."
                     ++ "\n  3. Review the APM API policy (rate limiting, client allow-list, contract enforcement)."
                     ++ "\n  4. Engage the APM team to grant permissions or whitelist the Mule IP."
                     ++ "\n  5. Once access is granted, resubmit: " ++ poSegment
                     ++ "\n\n  Do NOT resubmit until the permission issue is resolved."
    }
    else if (resolvedType == "SERVER_ERROR") {
        title:       "APM Internal Server Error (5xx)",
        bannerColor: "#dc2626",
        errorCode:   "APM_SERVER_ERROR",
        category:    "SERVER_ERROR",
        message:     "850 transmission failed with error type [SERVER_ERROR] — APM returned a server-side error while processing the 850 Purchase Order. " ++ descStr,
        resolution:  "The 850 transmission failed due to an internal error on the APM side."
                     ++ "\n  1. Check the APM application logs for stack traces around the time of failure."
                     ++ "\n  2. Confirm APM service health (memory, CPU, DB connections) in its monitoring dashboard."
                     ++ "\n  3. Determine if the failure is transient (overload) or persistent (bug/misconfiguration)."
                     ++ "\n  4. Escalate to the APM team with the transmissionId and timestamp."
                     ++ "\n  5. Once APM confirms stability, resubmit: " ++ poSegment
                     ++ "\n\n  Do NOT resubmit until APM confirms the root cause is fixed."
    }
    else if (resolvedType == "BAD_REQUEST")  {
        title:       "APM Bad Request (400)",
        bannerColor: "#f59e0b",
        errorCode:   "APM_BAD_REQUEST",
        category:    "PAYLOAD_ERROR",
        message:     "850 transmission failed with error type [BAD_REQUEST] — APM rejected the 850 payload with HTTP 400. " ++ descStr,
        resolution:  "The 850 transmission failed because APM could not process the request payload."
                     ++ "\n  1. Review the 850 payload — check for missing required fields or incorrect data types."
                     ++ "\n  2. Validate the payload against the APM API schema or contract."
                     ++ "\n  3. Check that all required HTTP headers (Content-Type, Accept, etc.) are correctly set."
                     ++ "\n  4. Coordinate with the APM team to identify which field triggered the rejection."
                     ++ "\n  5. Fix the payload mapping and resubmit: " ++ poSegment
                     ++ "\n\n  Do NOT resubmit the same payload — fix the data issue first."
    }
    else if (resolvedType == "VALIDATION")   {
        title:       "JSON Schema at Process API Failure",
        bannerColor: "#f59e0b",
        errorCode:   "APM_VALIDATION_ERROR",
        category:    "VALIDATION",
        message:     "850 transmission failed with error type [VALIDATION] — JSON Schema at Process API Failure. " ++ descStr,
        resolution:  "The 850 transmission failed because one or more fields in the payload did not pass APM validation."
                     ++ "\n  1. Review the validation error details returned by APM in the error description above."
                     ++ "\n  2. Identify the specific field(s) that failed validation (e.g., missing mandatory elements, incorrect format, invalid code values)."
                     ++ "\n  3. Validate the 850 payload against the APM API schema and EDI 850 X12 contract requirements."
                     ++ "\n  4. Check all date formats, numeric ranges, code set values, and mandatory segment presence."
                     ++ "\n  5. Coordinate with the APM team to obtain the full validation error report for: " ++ poSegment
                     ++ "\n  6. Correct the failing field(s) in the mapping transformation and resubmit."
                     ++ "\n\n  Do NOT resubmit the same payload — the data issue must be resolved first."
    }
    else                                     {
        title:       "APM Transmission Error",
        bannerColor: "#6b7280",
        errorCode:   "APM_UNKNOWN_ERROR",
        category:    "UNKNOWN",
        message:     "850 transmission failed with error type [" ++ resolvedType ++ "] while sending the 850 Purchase Order to APM. " ++ descStr,
        resolution:  "The 850 transmission failed with an unclassified error type [" ++ resolvedType ++ "] from APM."
                     ++ "\n  1. Review the full Mule error log for root cause and stack trace."
                     ++ "\n  2. Check the APM logs for a corresponding failure at the same timestamp."
                     ++ "\n  3. Escalate to the integration team with the correlationId and transmissionId."
                     ++ "\n  4. Once root cause is identified, resubmit: " ++ poSegment
                     ++ "\n\n  Do NOT resubmit until the root cause is understood."
    }

var descStr      = ((partner.description  default [])[0] default "") as String
var apmType      = ((partner.errorType    default [])[0] default "") as String
var httpCode     = extractHttpCode(descStr)
var resolvedType = resolveErrorType(apmType, httpCode)
var errorConfig  = buildErrorConfig(resolvedType, "")

var transmissionId =
    (partnerErrors map ((e) -> safe(e.transmissionIdApm as String, "N/A"))) joinBy " | "

var partnerRows =
    do {
        var poCount  = sizeOf(partnerErrors)
        var firstPo  = partnerErrors[0] default {}
        var firstRow =
            "<tr style='background:#fee2e2;color:#b91c1c;'>"
            ++ "<td style='padding:8px;border:1px solid #ddd;vertical-align:top;font-weight:600;' rowspan='" ++ poCount ++ "'>" ++ partnerId ++ "</td>"
            ++ "<td style='padding:8px;border:1px solid #ddd;vertical-align:top;font-weight:600;' rowspan='" ++ poCount ++ "'>" ++ resolvedType ++ "</td>"
            ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(firstPo.poNo as String, "N/A") ++ "</td>"
            ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ ((firstPo."Error Details" default []) joinBy "<br/>") ++ "</td>"
            ++ "</tr>"
        var remainingRows =
            (partnerErrors[1 to -1] default []) map ((poEntry) ->
                "<tr style='background:#fee2e2;color:#b91c1c;'>"
                ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(poEntry.poNo as String, "N/A") ++ "</td>"
                ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ ((poEntry."Error Details" default []) joinBy "<br/>") ++ "</td>"
                ++ "</tr>"
            )
        ---
        [firstRow] ++ remainingRows
    }

var validationHtml =
    if (sizeOf(partnerRows) > 0)
        "<table style='width:100%;border-collapse:collapse;margin-top:10px;'>"
        ++ "<tr style='background:#fecaca;'>"
        ++ "<th style='padding:8px;border:1px solid #ddd;'>Partner ID</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;'>Error Type</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;'>PO Number</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;'>Error Details</th>"
        ++ "</tr>"
        ++ (partnerRows joinBy "")
        ++ "</table>"
    else
        "Error occurred but no detailed information available."

var data = {
    flowDirection:    "OUTBOUND",
    documentType:     "850",
    appName:          p('api.name') default "Mule Application",
    transactionType:  "850",
    environment:      upper(p('mule.env') default "DEV"),
    flowName:         safe(vars.flowName, "850 Outbound Validation"),
    route:            "P21 → Mule → APM",
    partnerName:      partnerId ++ " — " ++ sizeOf(partnerErrors) ++ " PO(s) failed [" ++ resolvedType ++ "]",
    errorTitle:       errorConfig.title,
    bannerColor:      errorConfig.bannerColor,
    errorType:        resolvedType,
    errorCategory:    errorConfig.category,
    status:           "FAILED",
    errorCode:        errorConfig.errorCode,
    message:          errorConfig.message,
    errorResolution:  errorConfig.resolution,
    errorDescription: validationHtml,
    transmissionId:   transmissionId,
    keyLabel:         "Correlation ID",
    vendorName:       partnerId,
    companyName:      (vars.purchaseOrderData.value.company_no[0] default "N/A"),
    key:              correlationId,
    businessKey:      poSegment,
    timestamp:        now() as String {format: "yyyy-MM-dd HH:mm:ss"}
}

var template =
    readUrl("classpath://templates/error-template.html", "text/plain")
---
template replace /\$\{(\w+)\}/ with ((m) ->
    (data[m[1]] as String) default ""
)