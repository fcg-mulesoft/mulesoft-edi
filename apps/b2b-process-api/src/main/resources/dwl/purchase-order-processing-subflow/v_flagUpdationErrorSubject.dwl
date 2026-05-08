%dw 2.0
output application/json
fun safe(v, d="N/A") =
    if ( v == null or (v is String and trim(v) == "") ) d else v
fun resolvePartner(pId) =
    if ( p('partner.outbound.' ++ pId) != null ) p('partner.outbound.' ++ pId)
    else
        pId
var transactions = payload
var poNumbers =
    (transactions map (t) -> safe(t.po_no as String, "N/A")) distinctBy $ joinBy ", "
var vendorIds =
    (transactions map (t) -> resolvePartner(safe(t.vendor_id as String, "UNKNOWN"))) distinctBy $ joinBy ", "
var env          = p('mule.env')          default null
var apiName      = p('api.name')          default null
var intType      = vars.integration."integration-type"
                     default vars.initialVariables."integration-type"
                     default null
var companyNo    = vars.purchaseOrderData.value.company_no[0] default null
fun present(v) = v != null and (v as String) != ""
var segments = [if ( present(env) ) upper(env)            else null,
    "FCG ERROR ALERT",
    if ( present(intType) ) intType               else null,
    if ( present(poNumbers) ) "PO(s) " ++ (poNumbers as String) else null] filter present($)
---
segments joinBy " | "