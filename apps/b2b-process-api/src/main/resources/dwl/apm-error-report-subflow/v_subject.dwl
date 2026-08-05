%dw 2.0
output application/json
---
upper(p('mule.env')) ++  " | " ++ "FCG ERROR ALERT | "  ++ "Partner Manager Error Alert Notification | " ++ upper(payload.vendor) ++ " | " ++ now() as String {format: "yyyy-MM-dd HH:mm:ss"}