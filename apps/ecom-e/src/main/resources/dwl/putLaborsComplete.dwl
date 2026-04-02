%dw 2.0
output application/json
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
                                    "Value": payload[0].orderNo,
                                    "IgnoreIfEmpty": true
                                }
                            ],
                            "RelativeDateEdits": []
                        }
                    ]
                },
                {
                    "Name": "TP_SERVICELINE.tp_serviceline",
                    "BusinessObjectName": null,
                    "Type": "List",
                    "Keys": ["item_id", "serial_number"],
                    "Rows": [
                        {
                            "Edits": [
                                {
                                    "Name": "item_id",
                                    "Value": payload[0].assetId,
                                    "IgnoreIfEmpty": true
                                },
                                 {
                                    "Name": "serial_number",
                                    "Value": payload[0].serialNumber,
                                    "IgnoreIfEmpty": true
                                }
                            ],
                               "RelativeDateEdits": []
                        }
                    ]
                },
                {
                    "Name": "TP_PARTSANDLABOR.oe_line_service_labor",
                    "BusinessObjectName": null,
                    "Type": "List",
                    "Keys": [
                               if(payload[0].laborSequence != null) "labor_sequence" else "ufc_oe_line_service_labor_ud_sf_labor_id"
                        ],
                    "Rows": payload map ((item, index) -> 
                        {
                            "Edits": [
                            	{
                                    "Name": "ufc_oe_line_service_labor_ud_sf_labor_id",
                                    "Value": item.salesforceId,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                    "Name": "contacts_id",
                                    "Value": item.technicianId,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                    "Name": "service_labor_id",
                                    "Value": item.serviceLaborId,
                                    "IgnoreIfEmpty": true
                                },                               
                                {
                                    "Name": "hours_worked",
                                    "Value": item.hoursWorked,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                    "Name": "hours_charged",
                                    "Value": item.hoursCharged,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                    "Name": "labor_type_cd",
                                    "Value": item.laborTypeCd,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                    "Name": "labor_sequence",
                                    "Value": item.laborSequence,
                                    "IgnoreIfEmpty": true
                                }                                
                            ] filter ((item, index) -> item.Value != null),
                            "RelativeDateEdits": []
                        })
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