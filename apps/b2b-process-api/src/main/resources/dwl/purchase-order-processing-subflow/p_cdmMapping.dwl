%dw 2.0
output application/json
var senderId = Mule::p('fcg.edi_id')
---
(vars.purchaseOrderData.value groupBy $.po_no) pluck ((poItems, poNumber) -> {
	b2bMessage: {
		header: {
			senderId: senderId default "117414135T",
			receiverId: poItems[0].TP_edi_isa05_id,
			purchaseOrderNumber: poNumber,
			purchaseOrderDate: poItems[0].BEG05_PODate default "",
			purchaseOrderType: poItems[0].BEG01_PurposeCode default "",
			purchaseOrderTypeCode: poItems[0].BEG02_POTypeCode default "",
			currencyCode: poItems[0].CUR02_currency default "",
			contract_no: poItems[0].BEG06_contract_no default "",
			contacts: [{
				contactFunction: "BD",
				name: poItems[0].PER02_Name default "",
				commNumberQualifier: "EM",
				commNumber: poItems[0].PER04_email_address default ""
			}],
			paymentTerms: [{
				termsTypeCode: poItems[0].ITD01_TermsTypeCode,
				termsBasisDateCode: poItems[0].ITD02_TermsBasisDateCode,
				termsDiscountPercent: poItems[0].ITD03_TermsDiscountPercent,
				termsDiscountDueDate: poItems[0].ITD04_TermsDiscountDueDate,
				termsDiscountDaysDue: poItems[0].ITD05_TermsDiscountDaysDue,
				termsNetDueDate: poItems[0].ITD06_TermsNetDueDate,
				termsNetDays: poItems[0].ITD07_TermsNetDays,
				termsDescription: poItems[0].ITD12_TermsDescription
			}] filter ($.termsTypeCode != null),
			dates: [{
				dateQualifier: "002",
				date: poItems[0].DTM_002_DeliveryReq
			},
			{
				dateQualifier: "004",
				date: poItems[0].DTM_004_PO_Date
			},
			{
				dateQualifier: "010",
				date: poItems[0].DTM_010_Requested
			}] filter ($.date != null),
			carrier: [{
				scac: poItems[0].TD503_CarrierSCAC,
				routing: poItems[0].TD505_Routing
			}] filter ($.scac != null),
			freightTerms: [{
				freightTermsCode: poItems[0].FOB01,
				freightTermsDescription: poItems[0].FOB03,
				locationQualifier: poItems[0].FOB02
			}] filter ($.freightTermsCode != null or
				$.freightTermsDescription != null or
				$.locationQualifier != null),
			references: [{
				qualifier: "ZZ",
				description: poItems[0].N902_HDR_Note
			} ++
				(if (poItems[0].MSG01_Shipping_instruction != null) {
					messages: [{
						messageText: poItems[0].MSG01_Shipping_instruction
					}]
				} else {})],
			partyInformation: [{
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
				references: [{
					qualifier: "ST",
					referenceNumber: (poItems[0].REF_ST_02_Location_Id as String)
				},
				({
					qualifier: "CO",
					referenceNumber: (poItems[0].external_po_no)
				}) if ((poItems[0].BEG02_POTypeCode as String) == "DS"),
				{
					qualifier: "ZZ",
					referenceNumber: (poItems[0].REF_ZZ_02_Vendor_Id as String)
				}]
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
			}] filter ($.name != null or $.idCode != null)
		},
		detail: {
			lineItems: ((poItems groupBy $.line_no) pluck ((lineItems, lineNo) -> {
				lineNo: lineNo default "",
				qtyOrdered: lineItems[0].PO1_02_QtyOrdered default 0,
				uom: lineItems[0].PO1_03_UOM default "",
				unitPrice: lineItems[0].PO1_04_UnitPrice default 0,
				priceQualifier: "PE",
				vendorPartNumberQualifier: "VP",
				vendorPartNo: lineItems[0].supplier_part_no default "",
				buyerPartNumberQualifier: "BP",
				buyerPartNo: lineItems[0].item_id default "",
				productDescription: [if (lineItems[0].PID05_Description != null) {
					descriptionType: "F",
					description: lineItems[0].PID05_Description ++ if (lineItems[0].PID05_Extended_Desc != null) (" " ++ lineItems[0].PID05_Extended_Desc) else ""
				} else null,
				if (lineItems[0].PID05_LineConfig1 != null) {
					descriptionType: "config1",
					description: lineItems[0].PID05_LineConfig1
				} else null,
				if (lineItems[0].PID05_2nd_LineConfig2 != null) {
					descriptionType: "config2",
					description: lineItems[0].PID05_2nd_LineConfig2
				} else null] filter ($ != null),
				schedules: lineItems map (schedItem) -> {
					quantity: schedItem.PO1_02_QtyOrdered,
					uom: schedItem.PO1_03_UOM,
					dateQualifier: "002",
					scheduledDate: schedItem.DTM_002_DeliveryReq
				}
			})) orderBy ((item) -> item.lineNo as Number default 0)
		}
	},
	summary: {
		totalLineItems: sizeOf(poItems groupBy $.line_no),
		totalQuantity: sum(poItems.*PO1_02_QtyOrdered default [])
	}
}) orderBy ((po) -> po.b2bMessage.header.purchaseOrderNumber as Number default 0)