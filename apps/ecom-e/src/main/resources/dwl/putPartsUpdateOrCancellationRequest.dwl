%dw 2.0
output application/json 
---
payload.parts map ((item, index) -> {
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
                                    "Value": payload.orderNo,
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
                    "Keys": [
                        "item_id", "serial_number"
                    ],
                    "Rows": [
                        {
                            "Edits": [
                                {
                                    "Name": "item_id",
                                    "Value": item.assetId,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                    "Name": "serial_number",
                                    "Value": item.serialNumber,
                                    "IgnoreIfEmpty": true
                                }
                            ],
                            "RelativeDateEdits": []
                        }
                    ]
                },
                {
                    "Name": "TP_PARTSANDLABOR.oe_line_service_part",
                    "BusinessObjectName": null,
                    "Type": "List",
                    "Keys": 
                    	[
                    		("oe_line_service_part_uid") if(!isEmpty(item.userDefinedFields.oeLineServicePartUid)),
                    		("source_loc_id") if(item.sourceLocId != null),
                    		"item_id" 
                    	],
                    "Rows": [
                        {
                            "Edits": ([
                                {
                                    "Name": "item_id",
                                    "Value": item.itemId,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                    "Name": "source_loc_id",
                                    "Value": item.sourceLocId,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                	"Name": "oe_line_service_part_uid",
                                	"Value": item.userDefinedFields.oeLineServicePartUid,
                                	"IgnoreIfEmpty": true
                                },
                                ({
                                    "Name": "unit_quantity",
                                    "Value": item.unitQuantity,
                                    "IgnoreIfEmpty": true
                                }) if(item.disposition == null)
                            ]) filter ((item, index) -> item.Value != null),
                            
                            "RelativeDateEdits": []
                        }
                    ]
                },
                ({
                    "Name": "TP_PLDETAIL.oe_line_service_pl_detail",
                    "BusinessObjectName": null,
                    "Type": "Form",
                    "Keys": if(item.sourceLocId != null)([
                        "service_item_id",
                        "item_id",
                        "serial_number",
                        "source_loc_id"
                    ]) else ([
                        "service_item_id",
                        "item_id",
                        "serial_number"
                    ]),
                    "Rows": [
                        {
                            "Edits": ([
                                if(!(item.disFlagT default false))({
                                    "Name": "c_unit_qty_allocated",
                                    "Value": "0",
                                    "IgnoreIfEmpty": true
                                }) else null,
                                {
                                    "Name": "item_id",
                                    "Value": item.itemId,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                    "Name": "source_loc_id",
                                    "Value": item.sourceLocId,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                    "Name": "disposition",
                                    "Value": item.disposition,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                    "Name": "service_item_id",
                                    "Value": item.assetId,
                                    "IgnoreIfEmpty": true
                                },
                                {
                                    "Name": "serial_number",
                                    "Value": item.serialNumber,
                                    "IgnoreIfEmpty": true
                                }
                            ]) filter ((item, index) -> item.Value != null),
                            "RelativeDateEdits": []
                        }
                    ]
                }) if(item.disposition != null) 
            ],
            "Documents": null
        }
    ],
    "Query": null,
    "FieldMap": [],
    "TransactionSplitMethod": 0,
    "Parameters": null
})