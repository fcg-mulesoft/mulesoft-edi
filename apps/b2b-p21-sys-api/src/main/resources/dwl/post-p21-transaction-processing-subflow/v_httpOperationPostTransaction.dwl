%dw 2.0
output application/json

---
{
    method: Mule::p('p21.request.method.transaction'),
    host: Mule::p('p21.request.host'),
    port: Mule::p('p21.request.port'),
    basePath: Mule::p('p21.request.basePath.transaction'),
    path: Mule::p('p21.request.path.transaction'),

    headers: {
        "Authorization": "Bearer "++ (vars.accessToken default ""),
        "Content-Type": "application/json"
    },
    queryParams: {},
    uriParams: {}
}