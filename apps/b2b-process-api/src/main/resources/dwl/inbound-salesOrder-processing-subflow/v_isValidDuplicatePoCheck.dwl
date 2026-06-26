%dw 2.0
output application/json

var response = vars.duplicatePoResponse
var hasDuplicate = !isEmpty(response)

---
{
    isValid: !hasDuplicate,
    validationErrors:
        if (hasDuplicate)
            {
                duplicatePo: [
                    "The incoming Purchase Order already exists in the system for the given customer and ship-to combination."
                ]
            }
        else
            {}
}