%dw 2.0
import * from dw::core::Strings
output text/plain

fun safe(v, d="N/A") =
    if (v == null or (v is String and trim(v) == "")) d else v

var errorData = [payload] default []

var allPurchaseOrders = flatten(errorData map (v) -> v.purchaseOrders default [])
var totalErrors       = sizeOf(allPurchaseOrders)

var allDirections =
    (allPurchaseOrders map (po) -> upper(safe(po.direction as String, ""))) distinctBy $

var directionLabel =
    if (sizeOf(allDirections) > 1)       ""
    else if (sizeOf(allDirections) == 1) allDirections[0]
    else                                 "N/A"

var directionContext =
    if (sizeOf(allDirections) > 1) "INBOUND and OUTBOUND"
    else                            allDirections[0] default "N/A"

var vendorSummary =
    ((errorData map (v) -> safe(v.vendor as String, "UNKNOWN")) distinctBy $) joinBy ", "

var poSummary =
    ((allPurchaseOrders map (po) -> safe(po.poNumber as String, "N/A")) distinctBy $) joinBy ", "

fun msgCells(msg) =
    "<td style='padding:6px 8px;border:1px solid #ddd;font-size:11px;color:#b91c1c;background:#fff5f5;'>"
        ++ safe(msg.documentNumber        as String) ++ "</td>"
    ++ "<td style='padding:6px 8px;border:1px solid #ddd;font-size:11px;color:#b91c1c;background:#fff5f5;'>"
        ++ safe(msg.documentVersion       as String) ++ "</td>"
    ++ "<td style='padding:6px 8px;border:1px solid #ddd;font-size:11px;color:#b91c1c;background:#fff5f5;'>"
        ++ safe(msg.acknowledgementType   as String) ++ "</td>"
    ++ "<td style='padding:6px 8px;border:1px solid #ddd;font-size:11px;color:#b91c1c;background:#fff5f5;'>"
        ++ safe(msg.acknowledgementStatus as String) ++ "</td>"

fun buildRows(v, po) =
    do {
        var msgs     = po.messages default []
        var msgCount = sizeOf(msgs)
        var span     = if (msgCount > 1) " rowspan='" ++ (msgCount as String) ++ "'" else ""
        var tdStyle  = "padding:8px;border:1px solid #ddd;color:#b91c1c;vertical-align:top;background:#fee2e2;"

        var rawFlow  = safe((msgs[0].businessFlow default "") as String, "")
        var flowParts = rawFlow splitBy "-"
        var txnType  = if (sizeOf(flowParts) > 1) flowParts[sizeOf(flowParts) - 1] else safe(rawFlow, "N/A")

        var transmissionCells =
            "<td style='" ++ tdStyle ++ "font-weight:600;white-space:nowrap;'" ++ span ++ ">"
                ++ safe(v.vendor            as String) ++ "</td>"
            ++ "<td style='" ++ tdStyle ++ "white-space:nowrap;'"              ++ span ++ ">"
                ++ safe(po.poNumber          as String) ++ "</td>"
            ++ "<td style='" ++ tdStyle ++ "font-size:11px;word-break:break-all;'" ++ span ++ ">"
                ++ safe(po.transmissionId    as String) ++ "</td>"
            ++ "<td style='" ++ tdStyle ++ "white-space:nowrap;'"              ++ span ++ ">"
                ++ safe(po.direction         as String) ++ "</td>"
            ++ "<td style='" ++ tdStyle ++ "font-weight:600;white-space:nowrap;'" ++ span ++ ">"
                ++ txnType ++ "</td>"
            ++ "<td style='" ++ tdStyle ++ "'"                                 ++ span ++ ">"
                ++ safe(po.errorDetails      as String) ++ "</td>"

        var firstRow =
            if (msgCount == 0)
                "<tr>"
                ++ transmissionCells
                ++ "<td colspan='4' style='padding:8px;border:1px solid #ddd;font-size:11px;"
                   ++ "color:#999;font-style:italic;background:#fff5f5;'>No messages</td>"
                ++ "</tr>"
            else
                "<tr>" ++ transmissionCells ++ msgCells(msgs[0]) ++ "</tr>"

        var extraRows =
            if (msgCount > 1)
                ((msgs[1 to (msgCount - 1)]) map (msg) ->
                    "<tr>" ++ msgCells(msg) ++ "</tr>"
                ) joinBy ""
            else ""
        ---
        firstRow ++ extraRows
    }

var errorRows =
    flatten(errorData map (v) ->
        (v.purchaseOrders default []) map (po) -> buildRows(v, po)
    )

var errorTable =
    if (totalErrors > 0)
        "<div style='font-size:13px;font-weight:600;color:#9a3412;margin-bottom:10px;'>"
            ++ "Partner Manager Errors (" ++ (totalErrors as String) ++ ")</div>"
        ++ "<div style='overflow-x:auto;'>"
        ++ "<table style='width:100%;border-collapse:collapse;margin-bottom:4px;font-size:12px;'>"

        ++ "<tr style='background:#fecaca;'>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;color:#7f1d1d;white-space:nowrap;'>Partner</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;color:#7f1d1d;white-space:nowrap;'>PO Number</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;color:#7f1d1d;'>Transmission ID</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;color:#7f1d1d;'>Direction</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;color:#7f1d1d;white-space:nowrap;'>Txn Type</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;color:#7f1d1d;'>Error Details</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;color:#7f1d1d;'>Doc Number</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;color:#7f1d1d;white-space:nowrap;'>Doc Version</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;color:#7f1d1d;white-space:nowrap;'>Ack Type</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;color:#7f1d1d;white-space:nowrap;'>Ack Status</th>"
        ++ "</tr>"

        ++ (errorRows joinBy "")
        ++ "</table>"
        ++ "</div>"
    else
        "<div style='font-size:13px;color:#6b7280;font-style:italic;'>No errors found.</div>"

var data = {
    flowDirection:    "",
    directionContext: directionContext,
    documentType:     "EDI",
    appName:          "Mule Application",
    transactionType:  "EDI",
    environment:      "N/A",
    flowName:         "EDI Validation Handler",
    route:            "Partner Manager",
    partnerName:      vendorSummary,
    poNumbers:        poSummary,
    errorTitle:       "Partner Manager Error",
    bannerColor:      "#ef4444",
    errorType:        "PARTNER_MANAGER_ERROR",
    errorCategory:    "PARTNER_MANAGER",
    status:           "FAILED",
    errorCode:        "PARTNER_MANAGER_ERROR",
    message:          "Partner Manager processing failed with "
                      ++ (totalErrors as String) ++ " error(s) across " ++ directionLabel
                      ++ " transactions. Please review the details below and check Partner Manager logs before taking corrective action.",
    errorResolution:  "One or more EDI transactions failed during Partner Manager processing."
        ++ "\n  1. Navigate to Partner Manager and open the Monitoring section."
        ++ "\n  2. Search using the Transmission ID or PO Number from the table below to locate the failed transaction."
        ++ "\n  3. Review the Partner Manager logs to identify the root cause — check for partner configuration issues, missing identifiers, or mapping failures."
        ++ "\n  4. Verify the partner profile and trading partner agreements are correctly configured in Partner Manager."
        ++ "\n  5. If the error is due to EDI mapping, correct the mapping configuration and redeploy."
        ++ "\n  6. If the error is due to missing or incorrect partner identifiers, update the partner record in Partner Manager."
        ++ "\n  7. Once the root cause is resolved, request the partner to resend the original EDI file."
        ++ "\n\n  Do NOT reprocess the original file — all fixes must be applied in Partner Manager before resubmission.",
    errorDescription: errorTable,
    transmissionId:   "N/A",
    keyLabel:         "Correlation ID",
    key:              "N/A",
    timestamp:        now() as String {format: "yyyy-MM-dd HH:mm:ss"}
}

var template =
    readUrl("classpath://templates/error-template-apm.html", "text/plain")
---
template replace /\$\{(\w+)\}/ with ((m) ->
    (data[m[1]] as String) default ""
)
