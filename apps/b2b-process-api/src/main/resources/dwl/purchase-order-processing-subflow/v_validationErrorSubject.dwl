%dw 2.0
output application/json
---
"FCG ERROR ALERT | " ++ upper(p('mule.env')) ++ " | " ++ p('api.name') ++ " | " ++ vars.initialVariables."integration-type"