%dw 2.0
import * from dw::core::Strings
output application/json
 
fun present(v)          = v != null and (v as String) != ""
fun safe(v, d="N/A")    = if (v == null or (v is String and trim(v) == "")) d else v
fun resolvePartner(pId) = if (p('partner.outbound.' ++ pId) != null) p('partner.outbound.' ++ pId) else pId
 
var partner      = if (payload is String) read(payload, "application/json") else payload
 
var partnerId    = resolvePartner(safe(partner.partnerId as String, "UNKNOWN"))
var poNumbers    = (partner.errors default []) map ((e) -> e.poNo as String) filter present($)
 
var vendorSegment = if (present(partnerId)) partnerId else null
var poSegment     = if (sizeOf(poNumbers) > 0) "PO " ++ (poNumbers joinBy ", ") else null
 
var env       = p('mule.env')  default null
var apiName   = p('api.name')  default null
var intType   = vars.integration."integration-type"
                    default vars.initialVariables."integration-type"
                    default null
 
var segments = [
    if (present(env))       upper(env)    else null,
    "FCG ERROR ALERT",
    if (present(intType))   intType       else null,
    poSegment
] filter present($)
---
segments joinBy " | "