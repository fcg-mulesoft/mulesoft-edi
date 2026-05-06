%dw 2.0
output application/json
var groupedPOs = vars.purchaseOrderData.value groupBy $.po_no
---
groupedPOs pluck ((poItems, poNumber) -> {
  B2BMessage: {
    Header: {
      senderId: "117414135T",//Hardcoded
      receiverId: poItems[0].vendor_id as String,
      purchaseOrderNumber: poNumber,
      purchaseOrderDate: poItems[0].BEG05_PODate default "",
      purchaseOrderType: poItems[0].BEG01_PurposeCode default "",
      purchaseOrderTypeCode: poItems[0].BEG02_POTypeCode default "",
      currencyCode: poItems[0].CUR02_currency default "",
 
      contacts: [{
        contactFunction: "BD",
        name: poItems[0].PER02_Name default "",
        commNumberQualifier: "EM",
        commNumber: poItems[0].PER04_email_address default ""
      }],
 
      dates: [
        {
          dateQualifier: "002",
          date: poItems[0].DTM_002_DeliveryReq
        },
        {
          dateQualifier: "010",
          date: poItems[0].DTM_010_Requested
        }
      ] filter ($.date != null),
 
      carrier: [
        {
          scac: poItems[0].TD503_CarrierSCAC,
          routing: poItems[0].TD505_Routing
        }
      ] filter ($.scac != null),
 
      references:
        [
          {
            qualifier: "ZZ",
            description: "SPECIAL INSTRUCTIONS"
          }
          ++
          (
            if (poItems[0].MSG01_Shipping_instruction != null)
              {
                messages: [
                  { messageText: poItems[0].MSG01_Shipping_instruction }
                ]
              }
            else {}
          )
        ],
 
      partyInformation: [
        {
          qualifier: "BY",
          name: poItems[0].N1_BY_Name,
          idQualifier: "92",
          idCode: poItems[0].location_id as String,
          address1: poItems[0].N3_BY_Addr1,
          city: poItems[0].N4_BY_City,
          state: poItems[0].N4_BY_State,
          postalCode: poItems[0].N4_BY_Zip,
          country: poItems[0].N4_BY_Country
        },
        {
          qualifier: "BT",
          name: poItems[0].N1_BY_Name,
          idQualifier: "92",
          idCode: poItems[0].location_id as String,
          address1: poItems[0].N3_BY_Addr1,
          city: poItems[0].N4_BY_City,
          state: poItems[0].N4_BY_State,
          postalCode: poItems[0].N4_BY_Zip,
          country: poItems[0].N4_BY_Country
        },
        {
          qualifier: "ST",
          name: poItems[0].N1_ST_Name,
          idQualifier: "92",
          idCode: poItems[0].location_id as String,
          address1: poItems[0].N3_ST_Addr1,
          city: poItems[0].N4_ST_City,
          state: poItems[0].N4_ST_State,
          postalCode: poItems[0].N4_ST_Zip,
          country: poItems[0].N4_ST_Country,
          references: [
            {
              qualifier: "ST",
              referenceNumber: (poItems[0].REF_ST_02_Location_Id as String)
            },
            {
              qualifier: "ZZ",
              referenceNumber: (poItems[0].REF_ZZ_02_Vendor_Id as String)
            }
          ]
        },
        {
          qualifier: "SU",
          name: "",
          idQualifier: "92",
          idCode: poItems[0].N1_SU_ID as String,
          address1: poItems[0].N3_SU_Addr1,
          city: poItems[0].N4_SU_City,
          state: poItems[0].N4_SU_State,
          postalCode: poItems[0].N4_SU_Zip,
          country: poItems[0].N4_SU_Country
        }
      ] filter ($.name != null or $.idCode != null)
    },
 
    detail: {
      lineItems: poItems map (item) -> {
        lineNo: item.line_no default "",
        qtyOrdered: item.PO1_02_QtyOrdered default 0,
        uom: item.PO1_03_UOM default "",
        unitPrice: item.PO1_04_UnitPrice default 0,
        priceQualifier: "PE",
        vendorPartNumberQualifier: "VP",
        vendorPartNo: item.supplier_part_no default "",
        buyerPartNumberQualifier: "BP",
        buyerPartNo: item.item_id default "",
 
  productDescription:
    [
      if (item.PID05_Description != null)
        {
          descriptionType: "F",
          description: item.PID05_Description
        }
      else null,
 
      if (item.PID05_LineConfig1 != null)
        {
          descriptionType: "config1",
          description: item.PID05_LineConfig1
        }
      else null,
 
      if (item.PID05_2nd_LineConfig2 != null)
        {
          descriptionType: "config2",
          description: item.PID05_2nd_LineConfig2
        }
      else null,
 
      if (item.PID05_Extended_Desc != null)
        {
          descriptionType: "F",
          description: item.PID05_Extended_Desc
        }
      else null
    ]
    filter ($ != null),
 
schedules: [
  {
    quantity: item.PO1_02_QtyOrdered,
    uom: item.PO1_03_UOM,
    dateQualifier: "002",
    scheduledDate: item.DTM_002_DeliveryReq
  }
]
      }
    },
 
    Summary: {
      totalLineItems: sizeOf(poItems),
      totalQuantity: sum(poItems.*PO1_02_QtyOrdered default [])
    }
  }
})