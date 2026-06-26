%dw 2.0
output application/json
var toTime = now() as DateTime
var fromTime = payload as DateTime
---
{
	fromTime: (fromTime  as String {format: "yyyy-MM-dd"}) ++ "T" ++ (fromTime as String {format: "HH:mm:ssxxx"} as String),
	toTime: (toTime  as String {format: "yyyy-MM-dd"}) ++ "T" ++ (toTime as String {format: "HH:mm:ssxxx"} as String)
}