%dw 2.0
output application/json
---
entriesOf(
  payload
    filter ($.payload.status == "FAILED")
    groupBy ($.payload.partnerId)
)
map (entry) -> {
  partnerId: entry.key,
  errors: entry.value map (item) -> {
    poNo: item.payload.poNumber,
    transmissionIdApm: item.payload.transmissionId default "APM request failed for this PO",
    "Error Details": (
      item.payload.error 
        scan /\$\.B2BMessage\.Header\.partyInformation\[1\]\.(\w+): null found, string expected/
    ) map ($[1] ++ " is null")
  }
}
