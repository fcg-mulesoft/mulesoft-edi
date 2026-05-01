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
 
var rawPayload       = if (payload is String) read(payload, "application/json") else payload
var validationErrors = if (rawPayload is Array) rawPayload else [rawPayload]
 
var partnerRows =
    flatten(
        validationErrors map (partner) ->
            do {
                var partnerIdRaw = safe(partner.partnerId as String, "UNKNOWN")
                var partnerId    = resolvePartner(partnerIdRaw)
                var poList       = partner.errors default []
                var poCount      = sizeOf(poList)
                var firstPo      = poList[0]
                var firstRow =
                    "<tr style='background:#fee2e2;color:#b91c1c;'>"
                    ++ "<td style='padding:8px;border:1px solid #ddd;vertical-align:top;font-weight:600;' rowspan='" ++ poCount ++ "'>" ++ partnerId ++ "</td>"
                    ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(firstPo.poNo as String, "N/A") ++ "</td>"
                    ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ ((firstPo."Error Details" default []) joinBy ", ") ++ "</td>"
                    ++ "</tr>"
                var remainingRows =
                    (poList[1 to -1] default []) map (poEntry) ->
                        "<tr style='background:#fee2e2;color:#b91c1c;'>"
                        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ safe(poEntry.poNo as String, "N/A") ++ "</td>"
                        ++ "<td style='padding:8px;border:1px solid #ddd;'>" ++ ((poEntry."Error Details" default []) joinBy ", ") ++ "</td>"
                        ++ "</tr>"
                ---
                [firstRow] ++ remainingRows
            }
    )
 
var validationHtml =
    if (sizeOf(partnerRows) > 0)
        "<table style='width:100%;border-collapse:collapse;margin-top:10px;'>"
        ++ "<tr style='background:#fecaca;'>"
        ++ "<th style='padding:8px;border:1px solid #ddd;'>Partner ID</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;'>PO Number</th>"
        ++ "<th style='padding:8px;border:1px solid #ddd;'>Error Details</th>"
        ++ "</tr>"
        ++ (partnerRows joinBy "")
        ++ "</table>"
    else
        "Validation failed but no detailed errors available."
 
var partnerSummary =
    (validationErrors map (p) ->
        resolvePartner(safe(p.partnerId as String, "UNKNOWN"))
        ++ " — " ++ sizeOf(p.errors default []) ++ " PO(s) failed"
    ) joinBy " | "
 
var data = {
    flowDirection:   "OUTBOUND",
    documentType:    "850",
    appName:         p('api.name') default "Mule Application",
    transactionType: "850",
    environment:     upper(p('mule.env') default "DEV"),
    flowName:        safe(vars.flowName, "850 Outbound Validation"),
    route:           "P21 → Mule → APM",
    partnerName:     partnerSummary,
    errorTitle:      "850 Outbound Validation Error",
    bannerColor:     "#f59e0b",
    errorType:       "CUSTOM:VALIDATION_ERROR",
    errorCategory:   "VALIDATION",
    status:          "FAILED",
    errorCode:       "VALIDATION_ERROR",
    message:         "One or more 850 Purchase Orders failed outbound validation. The P21 ship-to address data is incomplete for the partners listed below.",
    errorResolution: "The outbound 850 validation failed due to missing ship-to address fields in P21."
        ++ "\n  1. Log into P21 and locate the ship-to address records for each flagged Partner ID."
        ++ "\n  2. Populate all null fields: name, address1, city, state, postalCode, and country."
        ++ "\n  3. Verify the address data is complete and accurate for each affected PO number."
        ++ "\n  4. Once corrected in P21, reprocess or resubmit the affected 850 transactions."
        ++ "\n  5. If the address fields are intentionally blank, confirm with the business team whether a default address should be applied."
        ++ "\n\n  Do NOT resubmit until all required address fields are populated in P21.",
    errorDescription: validationHtml,
    transmissionId:  payload.errors[0].transmissionIdApm,
    keyLabel:        "Partner IDs",
    key:             (validationErrors map (p) -> safe(p.partnerId as String, "UNKNOWN")) joinBy ", ",
    timestamp:       now() as String {format: "yyyy-MM-dd HH:mm:ss"}
}
 
var template =
    readUrl("classpath://templates/error-template.html", "text/plain")
---
template replace /\$\{(\w+)\}/ with ((m) ->
    (data[m[1]] as String) default ""
)