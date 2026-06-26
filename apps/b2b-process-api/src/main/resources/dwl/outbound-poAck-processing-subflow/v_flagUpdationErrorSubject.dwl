%dw 2.0

output application/json
 
fun present(v)          = v != null and (v as String) != ""

 
var poData = vars.ackData.value default []
 

var poNumbers =

    (poData map (row) -> row.order_no as String default null)

    filter present($)

    distinctBy $
 
var vendorIds =
    (poData map (row) -> (row."trading_partner_name" as String default ""))
    filter present($)
    distinctBy $
 
var env     = p('mule.env') default null

var apiName = p('api.name') default null

var intType = vars.integration."integration-type"

                default vars.initialVariables."integration-type"

                default null
 
var poSegment     = if (sizeOf(poNumbers) > 0) "PO(s) " ++ (poNumbers joinBy ", ") else null

var vendorSegment = if (sizeOf(vendorIds) > 0) vendorIds joinBy ", "               else null
 
var segments = [
    if (present(env))       upper(env)  else null,  
	"FCG ERROR ALERT",
    if (present(intType))   intType     else null,
    poSegment,
    vendorSegment

] filter present($)

---
segments joinBy " | "
