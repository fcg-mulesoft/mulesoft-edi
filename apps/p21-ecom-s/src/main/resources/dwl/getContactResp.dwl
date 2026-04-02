%dw 2.0
output application/json
---
{	
"contactId": payload.Id,
"salesforceId": payload.UserDefinedFields.SalesforceId,
"birthday": payload.Birthday,
"comments": payload.Comments,
"emailAddress": payload.EmailAddress,
"directFax": payload.DirectFax,
"homePhone": payload.HomePhone,
"cellular": payload.Cellular,
"firstName": payload.FirstName,
"lastName": payload.LastName,
"directPhone": payload.DirectPhone,
"title": payload.Title,
"addressId": payload.AddressId,
"contactUdUid": payload.UserDefinedFields.ContactsUdUid
}