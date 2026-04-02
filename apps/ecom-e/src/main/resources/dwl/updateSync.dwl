%dw 2.0

output application/json
---
{
   "Id": payload.contactId,
   "UserDefinedFields": {
         "ContactsUdUid": payload.udUid,
         "SalesforceId": payload.salesforceId,
          "SfLastSync": payload.sfLastSync
}
}



     
     

