%dw 2.0
output application/json
---
  {  "Name": "Shipping",
    "UseCodeValues": true,
    "IgnoreDisabled": false,
    "Transactions": [{
        "Status": "New",
        "DataElements": [{
            "Name": "TABPAGE_1.tp_1_dw_1",
            "BusinessObjectName": null,
            "Type": "Form",
            "Keys": [],
            "Rows": [{
                "Edits": [{
                        "Name": "pick_ticket_no",
                        "Value": payload,
                        "IgnoreIfEmpty": true
                    },
                    {
                        "Name": "delete_flag",
                        "Value": "Y",
                        "IgnoreIfEmpty": true
                    }
                ]
            }]
        }],
        "Documents": null
    }],
    "Query": null,
    "FieldMap": [],
    "TransactionSplitMethod": 0,
    "Parameters": null
}