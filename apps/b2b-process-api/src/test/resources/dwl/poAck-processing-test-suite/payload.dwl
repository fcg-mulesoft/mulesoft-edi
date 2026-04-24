%dw 2.0
output application/json
---
[
    {
        "b2bMessage": {
            "header": {
                "senderId": "1631404318T",
                "receiverId": "7048474464T",
                "version": "00401",
                "controlNumber": 194,
                "environment": "T",
                "groupControlNumber": 194,
                "groupVersion": "004010",
                "documentType": "855",
                "purposeCode": "Original",
                "acknowledgmentType": "Acknowledge – with detail and change",
                "poNumber": "40395444",
                "purchaseOrderDate": "2026-02-18T00:00:00+05:30",
                "partyInformation": [
                    {
                        "qualifier": "ST",
                        "name": "RANPAK SHELTON PLANT",
                        "address1": "57 WATERVIEW DR",
                        "additionalAddressLine2": "",
                        "city": "SHELTON",
                        "state": "CT",
                        "postalCode": "06484",
                        "countryCode": "US"
                    }
                ]
            },
            "detail": {
                "itemDetails": [
                    {
                        "lineNo": "000010",
                        "quantityOrdered": 4,
                        "unitOfMeasurementCode": "EA",
                        "unitPrice": 651.12,
                        "priceQualifier": "",
                        "vendorPartNo": "FES8022569",
                        "buyerPartNo": "1000080714",
                        "acknowledgments": [
                            {
                                "lineItemStatus": "IA",
                                "quantityAcknowledged": 4,
                                "unitOfMeasurementCode": "EA",
                                "dateQualifier": "017",
                                "scheduledDate": "2026-04-06T00:00:00+05:30"
                            }
                        ]
                    },
                    {
                        "lineNo": "000020",
                        "quantityOrdered": 8,
                        "unitOfMeasurementCode": "EA",
                        "unitPrice": 639.01,
                        "priceQualifier": "",
                        "vendorPartNo": "FES8022569",
                        "buyerPartNo": "1000031446",
                        "acknowledgments": [
                            {
                                "lineItemStatus": "IA",
                                "quantityAcknowledged": 8,
                                "unitOfMeasurementCode": "EA",
                                "dateQualifier": "017",
                                "scheduledDate": "2026-04-06T00:00:00+05:30"
                            }
                        ]
                    },
                    {
                        "lineNo": "000030",
                        "quantityOrdered": 16,
                        "unitOfMeasurementCode": "EA",
                        "unitPrice": 33.47,
                        "priceQualifier": "",
                        "vendorPartNo": "FES551392",
                        "buyerPartNo": "1000023322",
                        "acknowledgments": [
                            {
                                "lineItemStatus": "IA",
                                "quantityAcknowledged": 16,
                                "unitOfMeasurementCode": "EA",
                                "dateQualifier": "017",
                                "scheduledDate": "2026-04-06T00:00:00+05:30"
                            }
                        ]
                    }
                ]
            },
            "summary": {
                "totalLineItems": 3,
                "totalQuantity": 28
            }
        }
    }
]