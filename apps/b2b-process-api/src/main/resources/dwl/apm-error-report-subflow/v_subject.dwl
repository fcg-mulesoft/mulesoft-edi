%dw 2.0
output application/json
---
upper(p('mule.env')) ++  " | " ++ "FCG ERROR ALERT | " ++  " | "  ++ "APM Error Alert Notification"