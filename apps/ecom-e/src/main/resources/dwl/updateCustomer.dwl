%dw 2.0
output application/json
---
{
"customerId": payload.CustomerId,
"companyId": payload.CompanyId,
"salesforceId": payload.UserDefinedFields.SalesforceId,
"salesrepId": (payload.CustomerSalesreps.list filter ($.PrimarySalesrep == "Y")).SalesrepId[0],
"sicCode": payload.SicCode,
"currencyId": payload.CurrencyId,
"customerType": payload.CustomerType,
"legacyId": payload.LegacyId,
"customerUdUid": payload.UserDefinedFields.CustomerUdUid,
"customerAddress": 
{
	"name":payload.CustomerAddress.Name,
	"mailAddress1": payload.CustomerAddress.MailAddress1,
	"mailAddress2": payload.CustomerAddress.MailAddress2,
	"mailCity": payload.CustomerAddress.MailCity,
	"mailState": payload.CustomerAddress.mailState, 
	"mailPostalCode": payload.CustomerAddress.MailPostalCode,
	"mailCountry":payload.CustomerAddress.MailCountry,
	"centralPhoneNumber": payload.CustomerAddress.CentralPhoneNumber,
	"physAddress1": payload.CustomerAddress.PhysAddress1,
	"physAddress2": payload.CustomerAddress.PhysAddress2,
	"physCity": payload.CustomerAddress.PhysCity,
	 "physState": payload.CustomerAddress.PhysState,
     "physPostalCode": payload.CustomerAddress.PhysPostalCode,
     "physCountry": payload.CustomerAddress.PhysCountry
},
"CustomerContacts":payload.CustomerContacts.list map ((item, index) -> {"contactId":item.ContactId})
}