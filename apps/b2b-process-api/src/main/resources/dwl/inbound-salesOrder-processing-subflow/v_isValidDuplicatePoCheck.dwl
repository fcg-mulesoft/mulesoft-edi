%dw 2.0
output application/json
 
var response = vars.salesOrderLookUpData
 
var hasDuplicate = sizeOf(response) > 1 and (sizeOf(response filter ((item) -> item.po_no != "")) > 0)
var errorCount = if (hasDuplicate)
  1
else
  0
output application/json  
---
{
  isValid: errorCount == 0,
  validationErrors:
    if (hasDuplicate)
      {
        duplicatePo:[ "The incoming Purchase Order already exists in the system for the given customer and ship-to combination."],

      }
    else
     {}
}