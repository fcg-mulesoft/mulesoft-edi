%dw 2.0
---
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
                                ({
                                    "Name": "ufc_oe_hdr_ud_sf_work_order_no",
                                    "Value": payload.userDefinedFields.salesforceId,
                                    "IgnoreIfEmpty": true
                                }) if (!isEmpty(payload.userDefinedFields.salesforceId)),
                                {
                                    "Name": "ufc_oe_hdr_ud_sf_last_sync",
                                    "Value": payload.sfLastSync,
                                    "IgnoreIfEmpty": true
                                },
                                ({
                                    "Name": "ufc_oe_hdr_ud_closed_to_salesforce",
                                    "Value": payload.userDefinedFields.sendToSalesforce,
                                    "IgnoreIfEmpty": true
                                }) if(!isEmpty(payload.userDefinedFields.sendToSalesforce)),
                                ({
                                    "Name": "ufc_oe_hdr_ud_multiple_service_orders",
                                    "Value": payload.userDefinedFields.multiVisitsNeeded,
                                    "IgnoreIfEmpty": true
                                }) if(!isEmpty(payload.userDefinedFields.multiVisitsNeeded)),
                                ({
                                    "Name": "po_no",
                                    "Value": payload.userDefinedFields.purchaseOrderNumber,
                                    "IgnoreIfEmpty": true
                                }) if(!isEmpty(payload.userDefinedFields.purchaseOrderNumber)),
                                ({
                                    "Name": "ufc_oe_hdr_ud_complete_in_salesforce",
                                    "Value": payload.userDefinedFields.completeInSalesforce,
                                    "IgnoreIfEmpty": true
                                }) if(!isEmpty(payload.userDefinedFields.completeInSalesforce))
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