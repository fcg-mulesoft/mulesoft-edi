%dw 2.0
var ServiceOrder = payload.ServiceOrder
output application/json
---
{
    "orderNo": ServiceOrder.OrderNo,
    "locationId": ServiceOrder.LocationId,
    "customerId": ServiceOrder.CustomerId,
    "contactId": ServiceOrder.ContactId,
    "salesreps":ServiceOrder.Salesreps.*ServiceOrderSalesrep default [] map((item,index) -> {
        "salesRepId": item.SalesrepId, 
        "primarySalesrep": item.PrimarySalesrep
    }),
    "orderDate": ServiceOrder.OrderDate,
    "requestedDate": ServiceOrder.RequestedDate,
    "expectedCompletionDate": ServiceOrder.ExpectedCompletionDate,
    "companyId": ServiceOrder.CompanyId,
    "addressId": ServiceOrder.AddressId,
    "shipToName": ServiceOrder.Ship2Name,
    "shipToAdd1": ServiceOrder.OeHdrShip2Add1,
    "shipToAdd2": ServiceOrder.OeHdrShip2Add2,
    "shipToCity": ServiceOrder.OeHdrShip2City,
    "shipToState": ServiceOrder.OeHdrShip2State,
    "shipToZip": ServiceOrder.OeHdrShip2Zip,
    "shipToCountry": ServiceOrder.OeHdrShip2Country,
    "poNo": ServiceOrder.PoNo,
    "carrierId": ServiceOrder.CarrierId,
    "taker": ServiceOrder.Taker,
    "approved": ServiceOrder.Approved,
    "packingBasis": ServiceOrder.PackingBasis,
    "deliveryInstructions": ServiceOrder.DeliveryInstructions,
    "terms": ServiceOrder.Terms,
    "willCall": ServiceOrder.WillCall,
    "class1Id": ServiceOrder.Class1id,
    "class2Id": ServiceOrder.Class2id,
    "class3Id": ServiceOrder.Class3id,
    "class4Id": ServiceOrder.Class4id,
    "class5Id": ServiceOrder.Class5id,
    "freightCd": ServiceOrder.FreightCd,
    "invoiceBatchNumber": ServiceOrder.InvoiceBatchNumber,
    "quoteExpirationDate": ServiceOrder.QuoteExpirationDate,
    "serviceOrderPriorityId": ServiceOrder.ServiceOrderPriorityId,
    "orderNotes": ServiceOrder.Notes.*ServiceOrderNote default [] map ((item2, index) -> {
        "noteId": item2.NoteId,
		"topic": item2.Topic,
		"note": item2.Note,
		"mandatory": item2.Mandatory,
		"orderNo": item2.OrderNo,
        "lineNo": item2.LineNo
    }) ,
    "userDefinedFields": {
        "subjectSfdc": ServiceOrder.UserDefinedFields.SubjectSfdc,
        "udUid": ServiceOrder.UserDefinedFields.OeHdrUdUid,
        "descriptionSfdc": ServiceOrder.UserDefinedFields.DescriptionSfdc
    ,
    },
    "lines": payload.ServiceOrder.*Lines.*ServiceLine  map ((element, index) ->{
    "labor": element.*Labor.*ServiceOrderLineLabor default [] map((row,index) -> {
            "technicianId" : row.TechnicianId,
            "serviceLaborId": row.ServiceLaborId,
            "extendedDesc": row.ExtendedDesc default "",
            "hoursWorked": row.HoursWorked,
            "hoursCharged": row.HoursCharged,
            "laborType": row.LaborType,
            "serviceLaborUid": row.UserDefinedFields.OeLineServiceLaborUid,
            "laborSequence": row.LaborSequence,
            "serialNumber": row.SerialNumber,
            "salesforceId": row.UserDefinedFields.SfLaborId
        }),
       "parts": element.*Parts.*ServiceOrderLineParts default [] map ((object, index) -> {
           "itemId": object.ItemId,
           "unitQuantity": object.UnitQuantity,
           "unitOfMeasure": object.UnitOfMeasure,
           "disposition": object.Disposition,
           "sourceLocId": object.SourceLocId,
           "userDefinedFields": {
               "oeLineServicePartUid": object.UserDefinedFields.OeLineServicePartUid

           }
       }),
       "lineNotes": element.*Notes.*ServiceOrderLineNote default [] map ((object, index) -> {
           "noteId": object.NoteId,
           "topic": object.Topic,
			"note": object.Note,
			"mandatory": object.Mandatory,
			"orderNo": object.OrderNo,			
			"lineNo": object.LineNo
       }),
  "lineNo": element.LineNo,
  "itemId": element.ItemId,
  "serialNumber": element.SerialNumber,
  "unitPrice": element.UnitPrice,
  "status": element.Status,
  "userDefinedFields": {
      "oeLineServiceUid": element.UserDefinedFields.OeLineServiceUid
  }})

    }