%dw 2.0
output application/json
var filteredRecords =
    vars.invoiceData.value
        filter ((item) ->
            (item.date_last_modified as DateTime) >= vars.httpOperation.queryParams.lastModified
        )
var invoiceItems =
    filteredRecords groupBy ($.invoice_no ++ "_" ++ $.order_no)
    
---
invoiceItems pluck ((items, invoiceNo) -> {
	b2bMessage: {
		header: {
			senderId: Mule::p('fcg.edi_id'),
			receiverId: if(Mule::p('mule.env')!= "prod") (((items[0].TP_edi_isa05_id default "") as String) ++ "T") else ((items[0].TP_edi_isa05_id default "") as String),
			invoiceNumber: items[0].BIG02_InvNo,
			invoiceDate: items[0].BIG01_InvDate,
			purchaseOrderNumber: items[0].BIG04_PurchaseOrderNo,
			purchaseOrderDate: items[0].BIG03_OrderDate,
			transactionTypeCode: items[0].BIG07_TransTypeCode,
			references: [{
				qualifier: "PO",
				referenceNumber: items[0].REF_PO_Value
			},
 
                {
				qualifier: "PK",
				referenceNumber: items[0].REF_PK_Value
			},
 
                {
				qualifier: "ZZ",
				referenceNumber: (items[0].N104_SF_ID as String)
			}] filter ($.referenceNumber != null),
			partyInformation: [{
				qualifier: items[0].N101_VN_Qual,
				name: items[0].N102_VN_Name,
				idQualifier: items[0].N103_VN_Qual,
				idCode: (items[0].N104_VN_ID as String),
				address1: items[0].N301_VN_Addr,
				city: items[0].N401_VN_City,
				state: items[0].N402_VN_State,
				country: "US"
			},
 
                {
				qualifier: items[0].N101_BY_Qual,
				name: items[0].N102_BY_Name,
				idQualifier: items[0].N103_BY_Qual,
				idCode: (items[0].N104_BY_ID as String),
				address1: items[0].N301_BY_Addr,
				city: items[0].N401_BY_City,
				state: items[0].N402_BY_State,
				country: "US"
			},
 
                {
				qualifier: items[0].N101_ST_Qual,
				name: items[0].N102_ST_Name,
				idQualifier: items[0].N103_ST_Qual,
				idCode: (items[0].N104_ST_ID as String),
				address1: items[0].N301_ST_Addr,
				city: items[0].N401_ST_City,
				state: items[0].N402_ST_State,
				country: "US"
			},
 
                {
				qualifier: items[0].N101_SF_Qual,
				name: items[0].N102_SF_Name,
				idQualifier: items[0].N103_SF_Qual,
				idCode: (items[0].N104_SF_ID as String),
				address1: items[0].N301_SF_Addr,
				city: items[0].N401_SF_City,
				state: items[0].N402_SF_State,
				country: "US"
			}] filter ($.qualifier != null),
			dates: [{
				dateQualifier: items[0].DTM01_Qual,
				date: items[0].DTM02_ShipDate
			}] filter ($.dateQualifier != null and $.date != null)
		},
		detail: {
			lineItems: items map (item) -> {
				lineNo: item.IT101_LineID default "",
				qtyInvoiced: item.IT102_Qty default 0,
				uom: item.IT103_UOM default "",
				unitPrice: item.IT104_Price default 0,
				basisCode: item.IT105_Basis default "",
				productIds: [{
					qualifier: item.IT106_CustPartQual,
					id: item.IT107_CustPart
				},
 
                    {
					qualifier: item.IT108_VendPartQual,
					id: item.IT109_VendPart
				},
 
                    {
					qualifier: item.IT110_UPCQual,
					id: item.IT111_UPC_Fallback
				}] filter ($.qualifier != null and $.id != null),
				pricing: {
					priceCode: item.CTP02_PriceCode,
					unitPrice: item.CTP03_UnitPrice,
					quantity: item.CTP04_Qty,
					uom: item.CTP05_UOM
				},
				productDescription: [{
					descriptionType: item.PID01_Type,
					description: item.PID05_Description
				}] filter ($.description != null)
			}
		},
		summary: {
			totalAmount: items[0].TDS01_TotalAmountNoDecimal,
			totalLineItems: sizeOf(items)
		}
	}
})