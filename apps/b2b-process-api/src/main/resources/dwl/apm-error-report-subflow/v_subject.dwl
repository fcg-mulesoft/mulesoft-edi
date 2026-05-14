%dw 2.0
output application/json
---
upper(p('mule.env')) ++  " | " ++ "FCG ERROR ALERT | "  ++ "Partner Manager Error Alert Notification"