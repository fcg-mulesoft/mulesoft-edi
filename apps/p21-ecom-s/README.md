# p21_ecom_s
System API for E-com-P21 system

## Detailed Flow Outline.

Handles Service-level interface to P21 Database.
Uses both direct database connections and Epicor P21 provided API.

Most Requests are transformed to match Epicor P21 APIs, then passed to them, then the results transformed.  Some have additional error handling.

Epicor P21 APIs fall into two basic categories.  GET requests tend to be handled by a specific API that accepts an ID as  URL parameter.  Updates (POST/PUT/PATCH) are handled by a single API, with specific updates on target passed within the body of the request.

This MuleSoft flow abstracts much of that by providing, where possible, a ID-based request, then building the body to pass to the Epicor P21 API.

Requests handled in main flow (p21_ecom_s).  Logic of requests handled in implementation.xml.  Handling of P21 tokens processed in Common.xml.
HTTP Listener handles:

GET: \healthcheck
GET: \info

