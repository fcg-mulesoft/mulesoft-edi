%dw 2.0
output application/json
---
if(!isEmpty(payload.partnerId)) 
[Mule::p("partner.outbound." ++ payload.partnerId)] else []