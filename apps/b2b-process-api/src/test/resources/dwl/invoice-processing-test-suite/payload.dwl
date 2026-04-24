%dw 2.0
output application/json
---
[
  {
    "b2bMessage": {
      "header": {
        "senderId": "7048474464",
        "receiverId": "SPSAPEXWATER",
        "version": "00401",
        "controlNumber": 80600001,
        "environment": "P",
        "groupControlNumber": 80600001,
        "groupVersion": "004010",
        "documentType": "810",
        "invoiceDate": "2026-03-13T00:00:00+05:30",
        "invoiceNumber": "INV-TEST-003",
        "poDate": "",
        "poNumber": "40418062",
        "references": {
          "purchaseOrderReference": "",
          "internalVendorId": "V0001300",
          "billOfLading": "474347844283",
          "carrierReferenceNumber": "",
          "standardCarrierAlphaCode": ""
        },
        "deliveryDate": "",
        "shippedDate": "2026-03-13T00:00:00+05:30",
        "deliveredDate": "",
        "currencyEntityCode": "BY",
        "currencyCode": "USD",
        "contactInformation": [],
        "termsOfSale": {
          "termsTypeCode": "01",
          "termsBasisCode": "3",
          "termsDiscountPercent": 0,
          "termsDiscountDueDate": "2026-03-13T00:00:00+05:30",
          "termsDiscountDaysDue": 0,
          "termsNetDueDate": "2026-04-12T00:00:00+05:30",
          "termsNetDays": 30,
          "termsDescription": "Net 30"
        },
        "partyInformation": []
      },
      "detail": {
        "invoice": {
          "itemDetails": [
            {
              "lineNo": "1",
              "qtyInvoiced": 100,
              "uom": "EA",
              "unitPrice": 75.59,
              "unitPriceBasis": "",
              "buyerPartNo": null,
              "vendorPartNo": "WF3P02018JTIMONIUM",
              "upcCode": null,
              "primaryItemNumber": "WF3P02018JTIMONIUM",
              "itemDescription": "Line 1 - PASS (qty 100 of 960, price exact)"
            },
            {
              "lineNo": "2",
              "qtyInvoiced": 10,
              "uom": "EA",
              "unitPrice": 851.98,
              "unitPriceBasis": "",
              "buyerPartNo": null,
              "vendorPartNo": "HFU640UY020J",
              "upcCode": null,
              "primaryItemNumber": "HFU640UY020J",
              "itemDescription": "Line 2 - PASS (qty 10 of 16, price exact)"
            },
            {
              "lineNo": "3",
              "qtyInvoiced": 5,
              "uom": "EA",
              "unitPrice": 614.22,
              "unitPriceBasis": "",
              "buyerPartNo": null,
              "vendorPartNo": "HFU640UY045J",
              "upcCode": null,
              "primaryItemNumber": "HFU640UY045J",
              "itemDescription": "Line 3 - PASS (qty 5 of 8, price exact)"
            }
          ]
        }
      },
      "summary": {
        "totalAmount": 17072.00,
        "carrierDetail": {
          "carrierCode": "",
          "shippingMethod": "FedEx Ground",
          "trackingQualifier": "",
          "trackingNumber": ""
        },
        "taxInformation": [],
        "serviceAllowanceCharge": [],
        "totalLineItems": 3
      }
    }
  }
]