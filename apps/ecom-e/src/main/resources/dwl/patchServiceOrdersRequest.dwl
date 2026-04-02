{
    "Name": "ServiceOrder",
    "UseCodeValues": true,
    "IgnoreDisabled": true,
    "Transactions": [
        {
            "Status": "New",
            "DataElements": [
                {
                    "Name": "TP_SERVICEORDER.serviceorder",
                    "BusinessObjectName": null,
                    "Type": "Form",
                    "Keys": [
                        "order_no"
                    ],
                    "Rows": [
                        {
                            "Edits": [
                                {
                                    "Name": "order_no",
                                    "Value": payload.serviceOrderNo,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                    "Name": "ufc_oe_hdr_ud_sf_work_order_no",
                                    "Value": payload.salesforceId,
                                    "IgnoreIfEmpty": true
                                },                                
                                {
                                    "Name": "ufc_oe_hdr_ud_sf_last_sync",
                                    "Value": payload.sfLastSync,
                                    "IgnoreIfEmpty": true
                                }
                            ],
                            "RelativeDateEdits": []
                        }
                    ]
                }
            ],
            "Documents": null
        }
    ],
    "Query": null,
    "FieldMap": [],
    "TransactionSplitMethod": 0,
    "Parameters": null
}