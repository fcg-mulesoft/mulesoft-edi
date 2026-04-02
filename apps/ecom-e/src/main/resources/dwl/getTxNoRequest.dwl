%dw 2.0
output application/json
---
{
    "ServiceName": "ServiceOrder",
    "TransactionStates": [
        {
            "DataElementName": "TP_SERVICEORDER.serviceorder",
            "Keys": [
                {
                    "Name": "order_no",
                    "Value": attributes.uriParams.'id'
                }
            ]
        }
    ],
    "UseCodeValues": true
}