%dw 2.0
// flattens input for easier referencing.
// input =
// {
//     "orderNo": "1234",
//     "labor": [
//         {
//             "item": {
//                 "assetId": "assetId-1",
//                 "laborTypeCd": "laborTypeCd-1"
//             }
//         }
//     ]
// }
// output = 
// [
//     {
//         "orderNo": "1234",
//         "assetId": "assetId-1",
//         "laborTypeCd": "laborTypeCd-1"
//     }
// ]

var laborArray = (payload.labor map ((laborRecord, index) -> 
    {"orderNo": payload.orderNo} ++
    laborRecord
))
// Groups by unique keys for each transaction.
// Outputs Object with multiple keys,
// where each key is the groupBy values (e.g. "assetId~serialNumber-false")
// and the value for the key is an array of matched records.
output application/json
---
laborArray
groupBy ((item, index) -> (
    (item.assetId default "NoAsset")
    ++ "~" ++ (item.serialNumber default "NoSerialNumber"))
    ++ "~" ++ (isEmpty(item.laborSequence) as String)
)