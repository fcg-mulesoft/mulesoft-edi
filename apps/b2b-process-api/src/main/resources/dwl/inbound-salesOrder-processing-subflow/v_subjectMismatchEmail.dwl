%dw 2.0
import * from dw::core::Strings
output application/json
 
var env = Mule::p("mule.env") default "DEV"
var direction = "Inbound salesOrder 850 | "
var poData = vars.initialPayload[0]
var poNumbers = poData.b2bMessage.header.poNumber

var poSegment ="PO(s) " ++ (poNumbers default "")
   
---
env ++ " | FCG ERROR ALERT | " ++ direction ++ poSegment