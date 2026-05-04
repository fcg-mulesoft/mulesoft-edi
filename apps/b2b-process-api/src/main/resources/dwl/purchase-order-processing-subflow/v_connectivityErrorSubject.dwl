%dw 2.0
output application/json
 
var senderKey    = vars.initialPayload[0].b2bMessage.header.senderId as String
var msgVendorId  = p('partner.outbound.' ++ senderKey) default null
 
var env          = p('mule.env')          default null
var apiName      = p('api.name')          default null
var intType      = vars.integration."integration-type"
                     default vars.initialVariables."integration-type"
                     default null
var companyNo    = vars.purchaseOrderData.value.company_no[0] default null
var poNumber     = vars.initialPayload[0].b2bMessage.header.poNumber default null
 
fun present(v) = v != null and (v as String) != ""
 
var segments = [

    if (present(env))       upper(env)            else null,
    "FCG ERROR ALERT",    
    if (present(intType))   intType               else null,
    if (present(poNumber))  "PO(s) " ++ (poNumber as String) else null
] filter present($)
---
segments joinBy " | "