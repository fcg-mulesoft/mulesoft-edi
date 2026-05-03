%dw 2.0
import substring from dw::core::Strings
output application/json
---

vars.effectiveTransmissions default [] map (transmission) -> {
    direction: transmission.direction default "",
    partnerFrom: transmission.partnerFromIdentifierValue default "",
    partnerTo: transmission.partnerToIdentifierValue default "",
    businessKey: if ((transmission.businessDocumentKey default null) != null) 
                 (transmission.businessDocumentKey default "") 
              else 
                 (transmission.businessDocumentId default ""),
    errorMessage: if (sizeOf(transmission.transmissionSteps) > 0) 
                 transmission.transmissionSteps[-1].errorMessage 
               else ""
} 