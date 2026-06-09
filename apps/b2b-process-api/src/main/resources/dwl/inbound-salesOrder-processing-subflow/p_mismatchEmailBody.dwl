%dw 2.0
import * from dw::core::Strings
output text/plain

fun safe(v, d="N/A") =
    if ( v == null or (v is String and trim(v) == "") ) d else v

fun present(v) = v != null and (v as String) != ""

fun resolvePartner(pId) =
    if ( p('partner.outbound.' ++ pId) != null ) p('partner.outbound.' ++ pId)
    else
        pId

var partner      = if ( payload is String ) read(payload, "application/json") else payload
var partnerId    = resolvePartner(safe(partner.partnerId default "UNKNOWN"))
var partnerErrors = partner.errors default []
var poData = vars.initialPayload[0]
var poNumbers = poData.b2bMessage.header.poNumber

var poSegment ="PO(s) " ++ poNumbers
   

var transmissionId = uuid()

var partnerRows =
    do {
        var poCount  = sizeOf(partnerErrors)
        var firstPo  = partnerErrors[0] default {}
        var firstRow =
            "<tr style='background:#fff3cd;color:#856404;'>"
            ++ "<td style='padding:8px;border:1px solid #ddd;vertical-align:top;font-weight:600;' rowspan='" ++ poCount ++ "'>" ++ partnerId ++ "</td>"
            ++ "<td style='padding:8px;border:1px solid #ddd;vertical-align:top;font-weight:600;' rowspan='" ++ poCount ++ "'>PRICE_MISMATCH</td>"
            ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(firstPo.poNo default "N/A") ++ "</td>"
            ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ ((firstPo."Error Details" default []) joinBy "<br/>") ++ "</td>"
            ++ "</tr>"
        var remainingRows =
            (partnerErrors[1 to -1] default []) map ((poEntry) ->
                "<tr style='background:#fff3cd;color:#856404;'>"
                ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(poEntry.poNo as String, "N/A") ++ "</td>"
                ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ ((poEntry."Error Details" default []) joinBy "<br/>") ++ "</td>"
                ++ "</tr>")
        ---
        [firstRow] ++ remainingRows
    }

var validationHtml =
    "<table style='width:100%;border-collapse:collapse;margin-top:10px;'>"
    ++ "<tr style='background:#dbeafe;'>"
    ++ "<th style='padding:8px;border:1px solid #ddd;'>Total Lines</th>"
    ++ "<th style='padding:8px;border:1px solid #ddd;'>Successful Lines</th>"
    ++ "<th style='padding:8px;border:1px solid #ddd;'>Failed Lines</th>"
    ++ "<th style='padding:8px;border:1px solid #ddd;'>Overall Status</th>"
    ++ "</tr>"
    ++ "<tr>"
    ++ "<td style='padding:8px;border:1px solid #ddd;text-align:center;'>"
    ++ ((vars.isValid.validationSummary.totalLines default 0) as String)
    ++ "</td>"
    ++ "<td style='padding:8px;border:1px solid #ddd;text-align:center;'>"
    ++ ((vars.isValid.validationSummary.successfulLines default 0) as String)
    ++ "</td>"
    ++ "<td style='padding:8px;border:1px solid #ddd;text-align:center;'>"
    ++ ((vars.isValid.validationSummary.failedLines default 0) as String)
    ++ "</td>"
    ++ "<td style='padding:8px;border:1px solid #ddd;text-align:center;font-weight:bold;'>"
    ++ (vars.isValid.validationSummary.overallStatus default "UNKNOWN")
    ++ "</td>"
    ++ "</tr>"
    ++ "</table>"
    ++
    (
        if (vars.isValid.notesPreparation.addHeaderLevelNote default false)
            "<div style='margin-top:15px;padding:12px;border-left:4px solid #f59e0b;background:#fffbeb;'>"
            ++ "<div style='font-weight:600;color:#92400e;margin-bottom:6px;'>Header Level Note</div>"
            ++ "<div style='color:#374151;'>"
            ++ (vars.isValid.notesPreparation.headerLevelNote default "")
            ++ "</div>"
            ++ "</div>"
        else
            ""
    )

var data = {
    flowDirection:   "INBOUND",
    documentType:    "850 - Price Mismatch",
    appName:         p('api.name') default "Mule Application",
    transactionType: "850",
    environment:     upper(p('mule.env') default "DEV"),
    flowName:        safe(vars.flowName, "850 Inbound Price Mismatch Check"),
    route:           "Partner → Mule → P21",
    partnerName:     partnerId ++ " — " ++ sizeOf(partnerErrors) ++ " PO(s) with Price Mismatch — Pending CSR Review",
    errorTitle:      "Price Mismatch — CSR Review Required",
    bannerColor:     "#f59e0b",
    errorType:       "PRICE_MISMATCH",
    errorCategory:   "BUSINESS_RULE_VIOLATION",
    status:          "PENDING_CSR_REVIEW",
    errorCode:       "PRICE_MISMATCH_HOLD",
    message:         "Price mismatch detected on " ++ sizeOf(partnerErrors) ++ " PO(s) received from " ++ partnerId ++ ". The order(s) have been placed on hold and will not be processed further. A CSR has been notified and will manually review and resolve the discrepancy.",
    errorResolution: "A price mismatch was found between the partner-submitted PO and the price on record in our system."
                     ++ "\n  1. CSR to review the flagged PO(s): " ++ poSegment
                     ++ "\n  2. Compare partner invoice price vs. P21 system price."
                     ++ "\n  3. Coordinate with the partner or internal pricing team to resolve the discrepancy."
                     ++ "\n  4. Once resolved, manually release or reject the PO in P21."
                     ++ "\n  5. Notify the partner of the outcome and any corrective action required."
                     ++ "\n\n  Do NOT reprocess automatically — manual CSR action required.",
    errorDescription: validationHtml,
    transmissionId:  transmissionId default uuid(),
    keyLabel:        "Correlation ID",
    vendorName:      partnerId,
    companyName:     (vars.salesOrderLookUpData[0].company_id default "N/A"),
    key:             correlationId,
    businessKey:     poSegment,
    timestamp:       now() as String { format: "yyyy-MM-dd HH:mm:ss" }
}

var template =
    readUrl("classpath://templates/error-template.html", "text/plain")
---
template replace /\$\{(\w+)\}/ with ((m) ->
    (data[m[1]] as String) default "")