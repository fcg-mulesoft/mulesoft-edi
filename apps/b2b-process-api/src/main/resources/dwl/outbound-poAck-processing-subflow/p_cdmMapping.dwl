%dw 2.0
output application/json
 
var groupedOrders = vars.ackData.value groupBy $.BAK03_CustPO
 
---
groupedOrders pluck ((orderItems, orderNo) -> {
    b2bMessage: {
        header: {
			receiverId: orderItems[0].TP_edi_isa05_id ++ "T",
            senderId: Mule::p(lower(orderItems[0].trading_partner_name) ++ ".ack.senderId") ,
            acknowledgmentPurposeCode: orderItems[0].BAK01_Purpose,
            acknowledgmentType: orderItems[0].BAK02_AckType,
            purchaseOrderNumber: orderItems[0].BAK03_CustPO,
            purchaseOrderDate: orderItems[0].BAK04_Date,
            acknowledgementdate: orderItems[0].BAK09_po_ack_date,
            sellerOrderNumber: orderItems[0].BAK06_ReferenceNo,
 
            references: [
                {
                    qualifier: orderItems[0].REF01_InternalID_Qual,
                    referenceNumber: orderItems[0].REF02_InternalID
                }
            ] filter (
                !isEmpty($.qualifier default "") and
                !isEmpty($.referenceNumber default "")
            ),
 
            dates: [
                {
                    qualifier: orderItems[0].DTM01_EstimatedShip_Qual,
                    date: orderItems[0].DTM02_Date
                }
            ] filter (
                !isEmpty($.qualifier default "") and
                !isEmpty($.date default "")
            ),
 
            partyInformation: [
                {
                    qualifier: orderItems[0].N101_VN_Qual,
                    name: orderItems[0].N102_VN_Name,
                    idQualifier: orderItems[0].N103_VN_IDQual,
                    idCode: orderItems[0].N104_VN_ID as String,
                    address1: orderItems[0].N301_VN_Addr,
                    city: orderItems[0].N401_VN_City,
                    state: orderItems[0].N402_VN_State,
                    postalCode: orderItems[0].N403_VN_Zip
                },
                {
                    qualifier: orderItems[0].N101_SF_Qual,
                    name: orderItems[0].N102_SF_Name,
                    idQualifier: orderItems[0].N103_SF_IDQual,
                    idCode: orderItems[0].N104_SF_ID as String,
                    address1: orderItems[0].N301_SF_Addr,
                    city: orderItems[0].N401_SF_City,
                    state: orderItems[0].N402_SF_State,
                    postalCode: orderItems[0].N403_SF_Zip
                },
                {
                    qualifier: orderItems[0].N101_BY_Qual,
                    name: orderItems[0].N102_BY_Name,
                    idQualifier: orderItems[0].N103_BY_IDQual,
                    idCode: orderItems[0].N104_BY_ID as String,
                    address1: orderItems[0].N301_BY_Addr,
                    city: orderItems[0].N401_BY_City,
                    state: orderItems[0].N402_BY_State,
                    postalCode: orderItems[0].N403_BY_Zip
                },
                {
                    qualifier: orderItems[0].N101_ST_Qual,
                    name: orderItems[0].N102_ST_Name,
                    idQualifier: orderItems[0].N103_ST_IDQual,
                    idCode: orderItems[0].N104_ST_ID as String,
                    address1: orderItems[0].N301_ST_Addr,
                    city: orderItems[0].N401_ST_City,
                    state: orderItems[0].N402_ST_State,
                    postalCode: orderItems[0].N403_ST_Zip
                }
            ]
        },
 
        detail: {
            lineItems: orderItems map (item) -> (
                {
                    lineNo: item.PO1_01_LineID,
                    qty: item.PO1_02_Qty,
                    uom: item.PO1_03_UOM,
                    unitPrice: item.PO1_04_Price,
                    priceQualifier: item.PO1_05_PriceQual,
                    buyerPartQualifier: item.PO1_06_BuyerPartQual,
                    buyerPartNo: item.PO1_07_BuyerPart,
                    vendorPartQualifier: item.PO1_08_VendorPartQual,
                    vendorPartNo: item.PO1_09_VendorPart,
 
                    acknowledgments: [
                        {
                            statusCode: item.ACK01_Status,
                            quantity: item.ACK02_Qty,
                            uom: item.ACK03_UOM,
                            dateQualifier: item.ACK04_DateQual,
                            date: item.ACK05_Date
                        }
                    ]
                }
                ++
                (
                    if (!isEmpty(trim(item.PID05_Description default "")))
                    {
                        productDescriptions: [
                            {
                                descriptionType: item.PID01_Type,
                                description: trim(item.PID05_Description)
                            }
                        ]
                    }
                    else {}
                )
            )
        },
 
        summary: {
            totalLineItems: sizeOf(orderItems),
            totalAcknowledgedQuantity: sum(orderItems.*ACK02_Qty default [])
        }
    }
})