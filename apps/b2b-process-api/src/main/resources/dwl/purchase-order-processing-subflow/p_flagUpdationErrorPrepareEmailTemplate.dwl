%dw 2.0
import * from dw::core::Strings
output text/plain

fun safe(v, d="N/A") =
    if (v == null or (v is String and trim(v) == "")) d else v

fun resolvePartner(pId) =
    if (p('partner.' ++ pId) != null)
        p('partner.' ++ pId)
    else
        pId

var transactions = payload

var failedCount    = sizeOf(transactions) as String
var succeededCount = "0"
var otherCount     = "0"

var transactionRows =
    transactions map (t, idx) ->
        do {
            var poNo   = safe(t.po_no as String, "N/A")
            var vendorRaw = safe(t.vendor_id as String, "UNKNOWN")
            var vendor = resolvePartner(vendorRaw)
            var msg    = safe(t.message as String, "No message")
            var status = "Failed"
            var rowBg  = "background:#fee2e2;color:#b91c1c;"
            ---
            "<tr style='" ++ rowBg ++ "'>"
            ++ "<td style='padding:8px;border:1px solid #ddd;text-align:center;'>" ++ (idx + 1) ++ "</td>"
            ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ poNo ++ "</td>"
            ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ vendor ++ "</td>"
            ++ "<td style='padding:8px;border:1px solid #ddd;font-weight:600;'>" ++ status ++ "</td>"
            ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ msg ++ "</td>"
            ++ "</tr>"
        }

var summaryBar =
    "<table style='width:100%;border-collapse:collapse;margin-bottom:14px;'>"
    ++ "<tr>"
    ++ "<td style='padding:10px;text-align:center;background:#fee2e2;border-radius:6px;color:#b91c1c;font-weight:600;font-size:14px;width:33%;'>Failed: " ++ failedCount ++ "</td>"
    ++ "<td style='width:2%;'></td>"
    ++ "<td style='padding:10px;text-align:center;background:#dcfce7;border-radius:6px;color:#166534;font-weight:600;font-size:14px;width:33%;'>Succeeded: " ++ succeededCount ++ "</td>"
    ++ "<td style='width:2%;'></td>"
    ++ "<td style='padding:10px;text-align:center;background:#f1f5f9;border-radius:6px;color:#475569;font-weight:600;font-size:14px;width:30%;'>Other: " ++ otherCount ++ "</td>"
    ++ "</tr>"
    ++ "</table>"

var transactionTable =
    "<table style='width:100%;border-collapse:collapse;'>"
    ++ "<tr style='background:#fecaca;'>"
    ++ "<th style='padding:8px;border:1px solid #ddd;text-align:center;width:6%;'>#</th>"
    ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>PO Number</th>"
    ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Vendor</th>"
    ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Status</th>"
    ++ "<th style='padding:8px;border:1px solid #ddd;text-align:left;'>Message</th>"
    ++ "</tr>"
    ++ (transactionRows joinBy "")
    ++ "</table>"

var errorDescriptionHtml = summaryBar ++ transactionTable

var poNumbers =
    (transactions map (t) -> safe(t.po_no as String, "N/A")) distinctBy $ joinBy ", "

var vendorIds =
    (transactions map (t) -> resolvePartner(safe(t.vendor_id as String, "UNKNOWN")))
    distinctBy $
    joinBy ", "

var data = {
    flowDirection:   "OUTBOUND",
    documentType:    "850",
    appName:         p('api.name') default "Mule Application",
    transactionType: "850",
    environment:     upper(p('mule.env') default "DEV"),
    flowName:        safe(vars.flowName, "850 Outbound P21 Handler"),
    route:           "P21 → Mule → APM",
    partnerName:     "Vendor ID(s): " ++ vendorIds,
    errorTitle:      "850 P21 Transaction Error",
    bannerColor:     "#ef4444",
    errorType:       "CUSTOM:P21_FAILED",
    errorCategory:   "P21_ERROR",
    status:          "FAILED",
    errorCode:       "P21_FAILED",
    message:         "P21 returned " ++ failedCount ++ " failed transaction(s) out of "
                     ++ sizeOf(transactions) ++ " submitted for 850 Purchase Order processing. "
                     ++ "Please review the transaction details below.",
    errorResolution: "P21 transaction processing failed for one or more Purchase Orders."
        ++ "\n  1. Review each failed row in the table — note the PO Number and error message."
        ++ "\n  2. Log into P21 and locate the Purchase Order using the PO Number listed."
        ++ "\n  3. Check if 'Save' is enabled for the affected transaction set in P21 configuration."
        ++ "\n  4. Verify the vendor ID and PO status fields are correctly mapped and populated."
        ++ "\n  5. Correct the issue in P21 and resubmit the affected transactions."
        ++ "\n\n  Do NOT resubmit without confirming whether the transaction was partially saved in P21.",
    errorDescription: errorDescriptionHtml,
    transmissionId:  correlationId default uuid(),
    keyLabel:        "PO Number(s)",
    key:             poNumbers,
    timestamp:       now() as String {format: "yyyy-MM-dd HH:mm:ss"}
}

var template =
    readUrl("classpath://templates/error-template.html", "text/plain")
---
template replace /\$\{(\w+)\}/ with ((m) ->
    (data[m[1]] as String) default ""
)