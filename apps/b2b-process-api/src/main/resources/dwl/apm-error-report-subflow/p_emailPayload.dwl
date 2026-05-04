%dw 2.0
import * from dw::core::Strings
output text/plain

fun safe(v, d="N/A") =
    if (v == null or (v is String and trim(v) == "")) d else v

var transmissionData = vars.transmissionData default []
var messageData      = vars.messageData      default []

var totalTransmissions = sizeOf(transmissionData)
var totalMessages      = sizeOf(messageData)

var transmissionRows =
    transmissionData map (t) ->
        "<tr style='background:#fee2e2;color:#b91c1c;'>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(t.direction as String)    ++ "</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(t.partnerFrom as String)  ++ "</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(t.partnerTo as String)    ++ "</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(t.businessKey as String)  ++ "</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(t.errorMessage as String) ++ "</td>"
        ++ "</tr>"

var transmissionTable =
    if (totalTransmissions > 0)
        "<div style='font-size:13px;font-weight:600;color:#9a3412;margin-bottom:6px;margin-top:4px;'>Transmission Errors (" ++ totalTransmissions ++ ")</div>"
        ++ "<table style='width:100%;border-collapse:collapse;margin-bottom:16px;'>"
        ++ "<tr style='background:#fecaca;'>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Direction</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Partner From</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Partner To</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Business Key</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Error Message</th>"
        ++ "</tr>"
        ++ (transmissionRows joinBy "")
        ++ "</table>"
    else ""

var messageRows =
    messageData map (m) ->
        "<tr style='background:#fee2e2;color:#b91c1c;'>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(m.messageType as String)  ++ "</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(m.direction as String)    ++ "</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(m.partnerFrom as String)  ++ "</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(m.partnerTo as String)    ++ "</td>"
        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(m.businessKey as String)  ++ "</td>"
        ++ "</tr>"

var messageTable =
    if (totalMessages > 0)
        "<div style='font-size:13px;font-weight:600;color:#9a3412;margin-bottom:6px;'>Message Errors (" ++ totalMessages ++ ")</div>"
        ++ "<table style='width:100%;border-collapse:collapse;margin-bottom:16px;'>"
        ++ "<tr style='background:#fecaca;'>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Message Type</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Direction</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Partner From</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Partner To</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Business Key</th>"
        ++ "</tr>"
        ++ (messageRows joinBy "")
        ++ "</table>"
    else ""

var errorDescriptionHtml = transmissionTable ++ messageTable

fun resolvePartner(pId) =
    if (p('partner.' ++ pId) != null)
        p('partner.' ++ pId)
    else
        pId

var distinctPartners =
    (transmissionData map (t) -> resolvePartner(safe(t.partnerFrom as String, "UNKNOWN")))
    ++ (messageData map (m) -> resolvePartner(safe(m.partnerFrom as String, "UNKNOWN")))

var partnerSummary =
    (distinctPartners distinctBy $) joinBy ", "

var data = {
    flowDirection:   "INBOUND",
    documentType:    "EDI",
    appName:         p('api.name') default "Mule Application",
    transactionType: "EDI",
    environment:     upper(p('mule.env') default "DEV"),
    flowName:        safe(vars.flowName, "EDI Validation Handler"),
    route:           "Partner → Mule → System",
    partnerName:     partnerSummary,
    errorTitle:      "EDI Validation Error",
    bannerColor:     "#ef4444",
    errorType:       "CUSTOM:EDI_VALIDATION_ERROR",
    errorCategory:   "VALIDATION",
    status:          "FAILED",
    errorCode:       "EDI_VALIDATION_ERROR",
    message:         "EDI validation failed with "
                     ++ totalTransmissions ++ " transmission error(s) and "
                     ++ totalMessages ++ " message error(s). Please review the details below and correct the EDI data before resubmitting.",
    errorResolution: "One or more EDI transmissions or messages failed X12 validation."
        ++ "\n  1. Review each row in the tables below — identify the partner, direction, and business key for each failure."
        ++ "\n  2. Obtain the original EDI file from the partner listed under 'Partner From'."
        ++ "\n  3. Validate the file against the X12 specification for the relevant transaction set."
        ++ "\n  4. Correct any structural, segment, or element errors in the EDI file."
        ++ "\n  5. Request the partner to resend the corrected file."
        ++ "\n\n  Do NOT reprocess the original file — corrections must come from the source partner.",
    errorDescription: errorDescriptionHtml,
    transmissionId:  correlationId default uuid(),
    keyLabel:        "Correlation ID",
    key:             correlationId default uuid(),
    timestamp:       now() as String {format: "yyyy-MM-dd HH:mm:ss"}
}

var template =
    readUrl("classpath://templates/error-template.html", "text/plain")
---
template replace /\$\{(\w+)\}/ with ((m) ->
    (data[m[1]] as String) default ""
)