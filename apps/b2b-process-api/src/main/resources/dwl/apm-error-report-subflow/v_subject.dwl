%dw 2.0
output application/json
---
"FCG ERROR ALERT | " ++ upper(p('mule.env')) ++ " | " ++  " | " ++ "B2B Alert Notification"