%dw 2.0
output application/json
---
{
	"addressId" :  payload.addressId,
	"mailAddressId1" : payload.mailAddressId1,
	"mailAddressId2": payload.mailAddressId2,
	"mailCity": payload.mailCity,
	"mailState": payload.mailState,
	"mailPostalCode": payload.mailPostalCode,	
	"mailCountry": payload.mailCountry
	}
