%dw 2.0
output application/json
---
{
    "ServiceName": "Shipping",
    "TransactionStates": [
        {
            "DataElementName": "TABPAGE_1.tp_1_dw_1",
            "Keys": [
                {
                    "Name": "pick_ticket_no",
                    "Value": payload
                }
            ]
        }
    ],
    "UseCodeValues": true
}