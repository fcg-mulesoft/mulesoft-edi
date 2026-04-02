# ecom_e
System API for P21 system

## Detailed Flow Outline.

Handles Service-level interface to P21 Database.
Uses both direct database connections and Epicor P21 provided API.

Most Requests are transformed to match Epicor P21 APIs, then passed to them, then the results transformed.  Some have additional error handling.

Epicor P21 APIs fall into two basic categories.  GET requests tend to be handled by a specific API that accepts an ID as  URL parameter.  Updates (POST/PUT/PATCH) are handled by a single API, with specific updates on target passed within the body of the request.

This MuleSoft flow abstracts much of that by providing, where possible, a ID-based request, then building the body to pass to the Epicor P21 API.

Requests handled in main flow (ecom_e).  Logic of requests handled in implementation.xml.  Handling of P21 tokens processed in Common.xml.
HTTP Listener handles:

GET: \healthcheck
GET: \info

-- account-related 
GET: \customers\(id)
	Retrieves Epicore P21 Token (see common.xml)
	GET:  Epicore P21 API /uiserver0/api/V2/Transaction
	Has error-handling on return on inability to map fields.

GET: \contacts\(id)
	Retrieves Epicore P21 Token (see common.xml)
	GET:  Epicore P21 API /api/entity/contacts/{contactId}
	Has error-handling on return on inability to map fields.

GET: \addresses\(id)
	Retrieves Epicore P21 Token (see common.xml)
	GET:  Epicore P21 API /api/entity/addresses/{addressId}

PATCH: \customers\(id)
	Retrieves Epicore P21 Token (see common.xml)
	POST: Epicore P21 API /uiserver0/api/V2/Transaction (multi-use interface; updates are determined by data within payload)

PATCH: \contacts\(id)
	Retrieves Epicore P21 Token (see common.xml)
	POST: Epicore P21 API/uiserver0/api/V2/Transaction

-- work order related
GET: \serviceOrders\(id)
	Retrieves Epicore P21 Token (see common.xml)
	GET:  Epicore P21 API /api/service/serviceorders/{orderNo}
	Has error-handling on return on inability to map fields.

GET: \parts\(id) 
	Retrieves Epicore P21 Token (see common.xml)
	OPTIONS:  Epicore P21 API /api/inventory/v2/parts/{itemId} (double-check getPartsFlow)
	Has error-handling on return on inability to map fields.

PATCH: \serviceItems
	Retrieves Epicore P21 Token (see common.xml)
	For Each: 
		POST: Epicore P21 API/uiserver0/api/V2/Transaction (body originally built in Fieldservicemgmt-p)

GET: \serviceItems\invMasterUid
	Note: Does NOT Retrieve Epicore P21 Token (doesn't use the Epicor P21 API interface)
	For Each: 
		P21 DB: Execute Stored Procedure {call FCG_Get_sf_serviceinvmastuid(:serialNo,:shipToId)}

-- Work Order Complete Related
POST: \serviceOrdersComplete\(id)\orderNotes
	Note: Does NOT Retrieve Epicore P21 Token (doesn't use the Epicor P21 API interface)
	For Each: 
		P21 DB: Execute Stored Procedure {call FCG_sf_insert_so_hdrnote_sp(:orderNo,:notepadClassId,:topic,:note)}

PUT: \serviceOrdersComplete\(id)\labor:
	Retrieves Epicore P21 Token (see common.xml)
	Build multi-part payload of labor items (added, removed, or updated in request from SalesForce, via Fieldservicemgmt-p).
	For Each item in payload: 
		PUT: Epicore P21 API /uiserver0/api/V2/Transaction

GET: \serviceOrdersComplete\(id)\pickTickets\(pickTicketType)
	Retrieves Epicore P21 Token (see common.xml)
	GET: Epicore P21 API /uiserver0/api/v2/transaction/get (retrieves Shipment Transactions based on Order Number)
	Build multi-part payload of Shipment Transactions 
	For Each item in payload: 
		GET: Epicore P21 API /uiserver0/api/v2/transaction/get (retrieves Pick Ticket Items based on Ticket Number)
	Build multi-part payload of Items.

DELETE: \serviceOrdersComplete\(id)\pickTickets
	Retrieves Epicore P21 Token (see common.xml)
	For Each item in payload:
		POST: Epicore P21 API /uiserver0/api/V2/Transaction

PUT: \serviceOrdersComplete\(id)\parts
	Retrieves Epicore P21 Token (see common.xml)
	Build multi-part payload of Items for order, including by-line and disposition of item.
	For Each item in payload:
		POST: Epicore P21 API/uiserver0/api/V2/Transaction 
	

POST: \serviceOrdersComplete\(id)\lineNotes
	Note: Does NOT Retrieve Epicore P21 Token (doesn't use the Epicor P21 API interface)
	For Each: 
		P21 DB: Execute Stored Procedure {call FCG_sf_insert_so_linenote_sp(:orderNo,:assetId,:serialNumber,:notepadClassId,:topic,:note)}

PATCH: \serviceOrdersComplete\(id)
	Retrieves Epicore P21 Token (see common.xml)
	POST: Epicore P21 API/uiserver0/api/V2/Transaction 
	Has error-handling on POST
	
PATCH: \serviceOrders\(id)
	Retrieves Epicore P21 Token (see common.xml)
	POST:  Epicore P21 API /uiserver0/api/V2/Transaction (id passed as URI param, not in URL?)
	Has error-handling on POST

DELETE: \serviceOrdersComplete\(id)\labor
	Effectively a No-Op: Two Transforms that create a payload that might be passed back as a success message.
	
-- common.xml (used for most flows - to manage rollback/commit?)
Checks Object Store for existing Token (using passed Id).  
If exists:
	retrieves token.  
If Not Exists:
	requests token from Epicor P21 internal API (GET: /api/security/token/)
	Stores token to Object Store
Returns token.

