%dw 2.0
output application/json
---
entriesOf(
  (payload default [])
    filter ($.payload.status == "FAILED")
    groupBy ($.payload.partnerId default "UNKNOWN")
)
map (entry) -> {
  partnerId: entry.key,
 
  errors: entry.value map (item) -> {
    poNo: item.payload.poNumber,
 
    transmissionIdApm:
      item.payload.transmissionId
        default "APM request failed for this PO",
 
    "Error Details":
      if (
        !isEmpty(
          (
            ((item.payload.error default "") as String)
              scan /\$\.b2bMessage\.header\.partyInformation\[\d+\]\.(\w+): null found, string expected/
          ) map ($[1] ++ " is null")
        )
      )
      (
        (
          ((item.payload.error default "") as String)
            scan /\$\.b2bMessage\.header\.partyInformation\[\d+\]\.(\w+): null found, string expected/
        ) map ($[1] ++ " is null")
      )
      else
        [item.payload.error]
  },
 
  statusMessage:
    flatten(entry.value map ($.payload.statusMessage)),
 
  description:
    flatten(entry.value map ($.payload.description)),
 
  status:
    flatten(entry.value map ($.payload.statusCode)),
 
  errorType:
    flatten(entry.value map ($.payload.errorType))
}