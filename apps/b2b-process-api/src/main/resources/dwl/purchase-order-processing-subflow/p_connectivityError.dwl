%dw 2.0
import * from dw::core::Strings
output text/plain

fun safe(v, d="N/A")   = if (v == null or (v is String and trim(v) == "")) d else v
fun present(v)         = v != null and (v as String) != ""
fun resolveVendor(vid) = p('partner.outbound.' ++ vid) default vid

var integration = vars.integration default vars.initialVariables default {}

var rawSup   = error.suppressedErrors[0]   default null
var rawSupId = rawSup.errorType.identifier default ""
var rawSupNs = rawSup.errorType.namespace  default ""
var rawErrNs = error.errorType.namespace   default "UNKNOWN"
var rawErrId = error.errorType.identifier  default "ERROR"

var poData = vars.purchaseOrderData.value default []

var poNumbers =
    (poData map (row) -> row.po_no as String default null)
    filter present($)
    distinctBy $

var vendorIds =
    (poData map (row) -> resolveVendor(row.vendor_id as String default ""))
    filter present($)
    distinctBy $

var msgPoNumber  = if (sizeOf(poNumbers) > 0) poNumbers joinBy ", " else "N/A"
var msgVendorId  = if (sizeOf(vendorIds) > 0) vendorIds joinBy ", " else "N/A"
var msgCompanyNo = safe((poData[0].company_no) as String, "N/A")

var sourceSystem = safe(integration.source, "APM")
var targetSystem = safe(integration.target, "P21")

var errorTypeValue =
    (if (rawSupNs != "") rawSupNs else "UNKNOWN") ++ ":" ++
    (if (rawSupId != "") rawSupId else "UNKNOWN")

var categoryId = if (rawSupId != "") rawSupId else rawErrId
var categoryNs = if (rawSupNs != "") rawSupNs else rawErrNs

var errorResolution =
    do {
        var base =
            "The integration attempted to call the P21 API multiple times but was unable to establish a connection. All retry attempts were exhausted. The underlying error was: " ++ rawSupNs ++ ":" ++ rawSupId ++ "."
        var steps =
            if (categoryId == "TIMEOUT" or categoryId == "CONNECTION_TIMEOUT" or categoryId == "GATEWAY_TIMEOUT")
                "\n  1. The Mule integration made repeated attempts to reach the P21 API and every attempt timed out."
                ++ "\n  2. The root cause of each failure was: " ++ rawSupNs ++ ":" ++ rawSupId ++ " — refer to the error description below for full details."
                ++ "\n  3. Log into P21 and verify the system is healthy and responsive."
                ++ "\n  4. Check whether any long-running P21 jobs or batch processes are currently active and consuming resources."
                ++ "\n  5. Verify that the P21 API host URL, port, and endpoint configured in the integration are still correct and reachable from the Mule environment."
                ++ "\n  6. Confirm there are no firewall rules, VPN changes, or network policies blocking outbound calls from Mule to P21."
                ++ "\n  7. If P21 appears healthy, the timeout threshold in the integration may need to be increased — contact the integration support team."
                ++ "\n  8. Do not retry manually — contact the integration support team with the Correlation ID to investigate and reprocess once P21 is confirmed available."
            else if (categoryId == "READ_TIMEOUT" or categoryId == "WRITE_TIMEOUT")
                "\n  1. The Mule integration connected to P21 on each attempt but data transfer did not complete within the allowed time — all retries exhausted."
                ++ "\n  2. P21 may be processing a large payload or experiencing internal delays that cause it to stall mid-response."
                ++ "\n  3. Log into P21 and check system health — look for active jobs, slow queries, or resource contention."
                ++ "\n  4. Review P21 application logs around the time of failure for any internal errors or warnings."
                ++ "\n  5. Contact the integration support team with the Correlation ID — the read/write timeout values in Mule may need to be tuned."
                ++ "\n  6. Do not retry manually — the support team will reprocess once the issue is identified and resolved."
            else if (categoryId == "SSL_ERROR")
                "\n  1. Every retry attempt failed due to a TLS/SSL handshake error when connecting to P21."
                ++ "\n  2. The P21 server certificate may have expired, been renewed with a new certificate authority, or the Mule truststore may be outdated."
                ++ "\n  3. Contact the integration support team immediately — the Mule truststore or the P21 SSL certificate configuration needs to be reviewed and corrected."
                ++ "\n  4. Contact the P21 administrator to verify the current certificate status on the P21 API server."
                ++ "\n  5. Do not retry until the certificate issue has been confirmed as resolved by both teams."
            else if (categoryId == "SERVICE_UNAVAILABLE")
                "\n  1. Every retry attempt received a 503 Service Unavailable response from P21 — P21 may be undergoing maintenance or a restart."
                ++ "\n  2. Contact the P21 system administrator to confirm whether a planned or unplanned outage is in progress."
                ++ "\n  3. Do not retry until P21 is confirmed back online and fully operational."
                ++ "\n  4. Contact the integration support team with the Correlation ID if the service remains unavailable for more than 30 minutes — they will reprocess the transaction once P21 recovers."
            else if (categoryId == "REMOTELY_CLOSED")
                "\n  1. P21 accepted each connection attempt but closed it unexpectedly before the transaction could complete — all retries exhausted."
                ++ "\n  2. This may indicate a P21 application crash, a forced connection timeout on the P21 side, or a load balancer interruption between Mule and P21."
                ++ "\n  3. Review P21 application logs around the time of failure for any crashes, restarts, or forced disconnections."
                ++ "\n  4. Check whether a load balancer or reverse proxy sits in front of P21 and review its connection timeout settings."
                ++ "\n  5. Contact the P21 administrator and the integration support team with the Correlation ID."
            else if (categoryId == "BAD_GATEWAY")
                "\n  1. Every retry attempt received a bad gateway error — an intermediate component between Mule and P21 is returning an error response."
                ++ "\n  2. Check whether a load balancer, reverse proxy, or API gateway sits in front of P21 and review its health and logs."
                ++ "\n  3. Verify the P21 API endpoint URL and port are correctly configured in the integration."
                ++ "\n  4. Contact the integration support team and the P21 administrator with the Correlation ID."
            else if (categoryId == "CONNECTIVITY")
                "\n  1. The Mule integration was unable to establish a network connection to P21 on every retry attempt."
                ++ "\n  2. Verify that the P21 API service is running and the host is reachable from the Mule environment."
                ++ "\n  3. Check the P21 host URL, port, and endpoint URL configured in Mule for correctness."
                ++ "\n  4. Confirm there are no firewall rules or network policy changes blocking outbound calls from Mule to P21."
                ++ "\n  5. Contact the integration support team with the Correlation ID to investigate further."
            else
                "\n  1. The Mule integration made repeated attempts to reach the P21 API and all attempts failed."
                ++ "\n  2. The root cause of each failure was: " ++ rawSupNs ++ ":" ++ rawSupId ++ " — refer to the error description below for details."
                ++ "\n  3. Verify that the P21 API service is running and reachable from the Mule environment."
                ++ "\n  4. Check the P21 host URL, port, and endpoint configured in the integration for correctness."
                ++ "\n  5. Confirm there are no firewall rules, VPN changes, or network policies blocking outbound calls from Mule to P21."
                ++ "\n  6. Contact the P21 system administrator to verify the API service status and check P21 application logs around the time of failure."
                ++ "\n  7. Do not retry manually — contact the integration support team with the Correlation ID to investigate and reprocess once P21 is confirmed available."
        ---
        base ++ steps
        ++ "\n\n  No data was lost — the transaction can be safely resubmitted once P21 connectivity is restored and confirmed."
    }

var errorDescFull =
    "<p style='background:#fef3c7;border-left:4px solid #f59e0b;padding:10px;margin-bottom:10px;'>"
    ++ "<strong>All retry attempts to reach P21 were exhausted.</strong> "
    ++ "The integration retried the outbound call to P21 multiple times and could not recover. "
    ++ "The underlying error that caused every attempt to fail is shown below."
    ++ "</p>"
    ++ (rawSup.detailedDescription
            default rawSup.description
            default (rawSupNs ++ ":" ++ rawSupId))
    ++ "\n\nCorrelation ID: " ++ (correlationId default uuid())
    ++ "\nActual Error:   " ++ rawSupNs ++ ":" ++ rawSupId
    ++ "\nWrapper Error:  " ++ rawErrNs ++ ":" ++ rawErrId
    ++ "\nTimestamp:      " ++ (now() as String {format: "yyyy-MM-dd HH:mm:ss"})

var subjectSegments = [
    "FCG ERROR ALERT",
    if (present(upper(p('mule.env') default "")))           upper(p('mule.env') default "")  else null,
    if (present(p('api.name') default ""))                  p('api.name')                     else null,
    if (present(msgVendorId) and msgVendorId != "N/A")      msgVendorId                       else null,
    if (present(integration."integration-type" default "")) integration."integration-type"    else null,
    if (present(msgCompanyNo) and msgCompanyNo != "N/A")    msgCompanyNo                      else null,
    if (present(msgPoNumber) and msgPoNumber != "N/A")      "PO(s) " ++ msgPoNumber           else null
] filter present($)

var data = {
    flowDirection:    "OUTBOUND",
    documentType:     safe(integration."integration-type", "API"),
    appName:          p('api.name') default "Mule Application",
    transactionType:  safe(integration."integration-type", "API"),
    environment:      upper(p('mule.env') default "DEV"),
    route:            sourceSystem ++ " → Mule → " ++ targetSystem,
    partnerName:      msgVendorId,
    errorTitle:       "Connectivity Error",
    bannerColor:      "#6366f1",
    errorType:        errorTypeValue,
    errorCategory:    "CONNECTIVITY",
    status:           "FAILED",
    errorCode:        rawSupId,
    subject:          subjectSegments joinBy " | ",
    message:          "Failed to reach P21"
                      ++ (if (present(msgPoNumber) and msgPoNumber != "N/A") " while processing PO(s) " ++ msgPoNumber else "")
                      ++ (if (present(msgVendorId) and msgVendorId != "N/A") " (Vendor: " ++ msgVendorId ++ ")" else "")
                      ++ ". Error: " ++ rawSupNs ++ ":" ++ rawSupId ++ ".",
    errorResolution:  errorResolution,
    errorDescription: errorDescFull,
    transmissionId:   "N/A",
    keyLabel:         "Correlation ID",
    key:              correlationId default uuid(),
    vendorName:       msgVendorId,
    companyName:      msgCompanyNo,
    businessKey:      msgPoNumber,
    timestamp:        now() as String {format: "yyyy-MM-dd HH:mm:ss"}
}

var template =
    readUrl("classpath://templates/error-template.html", "text/plain")
---
template replace /\$\{(\w+)\}/ with ((m) ->
    (data[m[1]] as String) default ""
)