%dw 2.0
output text/plain

fun safe(v, d = "N/A") =
    if (v == null or (v is String and trim(v) == "")) d else v

var errResp = vars.errorResponse default {}
var sysInfo = vars.systemInformation default {}

var rawErrNs = error.errorType.namespace default "UNKNOWN"
var rawErrId = error.errorType.identifier default "ERROR"

var isAzureError = rawErrNs == "AZURE-STORAGE"

var isConnectivityError =
    rawErrId == "TIMEOUT" or
    rawErrId == "CONNECTION_TIMEOUT" or
    rawErrId == "GATEWAY_TIMEOUT" or
    rawErrId == "RETRY_EXHAUSTED" or
    rawErrId == "REMOTELY_CLOSED" or
    rawErrId == "SSL_ERROR" or
    rawErrId == "SERVICE_UNAVAILABLE"

var errorCategory =
    if (rawErrNs == "APIKIT") "APIKIT"
    else if (isAzureError or isConnectivityError) "AZURE_CONNECTIVITY"
    else "GENERIC"

var errorTitle =
    if (errorCategory == "APIKIT") "API Error"
    else if (errorCategory == "AZURE_CONNECTIVITY") "Azure Blob Storage Error"
    else "System Error"

var bannerColor =
    if (errorCategory == "APIKIT") "#ef4444"
    else if (errorCategory == "AZURE_CONNECTIVITY") "#0078d4"
    else "#ef4444"

var errorTypeValue =
    if (!isEmpty(errResp.statusMessage default ""))
        errResp.statusMessage as String
    else
        rawErrNs ++ ":" ++ rawErrId

var httpMethod = upper(attributes.method default "")

var azureOperation =
    if (httpMethod == "POST") "upload to"
    else if (httpMethod == "GET") "download from"
    else "access"

var errorResolution =
    if (errorCategory == "APIKIT")
        "The request was not formatted correctly and could not be accepted by the system."
        ++ "\n  1. This is usually caused by a missing or invalid request parameter / header."
        ++ "\n  2. Review the API specification and ensure all required fields are provided."
        ++ "\n  3. Contact the integration support team with the Correlation ID shown below if the issue persists."

    else if (errorCategory == "AZURE_CONNECTIVITY")
        do {
            var base =
                if (rawErrId == "RETRY_EXHAUSTED")
                    "The system attempted to reach Azure Blob Storage multiple times but all attempts failed."
                    ++ "\n  1. Azure Blob Storage may be experiencing an outage — check Azure Service Health."
                    ++ "\n  2. Do not retry manually — contact the IT support team to investigate."
                    ++ "\n  3. The support team will reprocess the request once Azure is back online."

                else if (
                    rawErrId == "TIMEOUT" or
                    rawErrId == "CONNECTION_TIMEOUT" or
                    rawErrId == "GATEWAY_TIMEOUT"
                )
                    "Azure Blob Storage did not respond in time — it may be under heavy load or temporarily unavailable."
                    ++ "\n  1. Wait a few minutes and retry the request."
                    ++ "\n  2. If the timeout persists, check Azure Service Health for any active incidents."
                    ++ "\n  3. Contact the IT support team with the Correlation ID if the issue continues."

                else if (rawErrId == "SSL_ERROR")
                    "A TLS/SSL certificate issue prevented the connection to Azure Blob Storage."
                    ++ "\n  1. This is a configuration issue — contact the IT support team immediately."
                    ++ "\n  2. Provide the Correlation ID when raising the issue."
                    ++ "\n  3. Do not retry until the certificate issue has been resolved."

                else if (rawErrNs == "AZURE-STORAGE")
                    "The Azure Blob Storage connector returned an error while attempting to "
                    ++ azureOperation
                    ++ " Azure Blob Storage."
                    ++ "\n  1. Verify that the container name and SAS token configured for this environment are valid and have not expired."
                    ++ "\n  2. Confirm that the blob path (folder/filename) is correct."
                    ++ "\n  3. Check Azure Blob Storage access policies and ensure the connector has the required permissions."
                    ++ "\n  4. Contact the IT support team with the Correlation ID if the issue cannot be resolved."

                else
                    "The integration was unable to connect to Azure Blob Storage."
                    ++ "\n  1. Check whether Azure Blob Storage is reachable from the Mule environment."
                    ++ "\n  2. Try resubmitting the request after a few minutes."
                    ++ "\n  3. Contact the IT support team with the Correlation ID if the problem persists."
            ---
            base ++ "\n\n  No data was permanently lost — the request can be safely resubmitted once the issue is resolved."
        }

    else
        "An unexpected error occurred while processing this request."
        ++ "\n  1. Contact the integration support team with the Correlation ID shown below."
        ++ "\n  2. Do not resubmit until you have heard back from the support team."

var errorDescFull =
    (safe(
        errResp.description,
        error.detailedDescription default error.description default "Unexpected error"
    ) as String)
    ++ "\n\nCorrelation ID: "
    ++ safe(errResp.correlationId, correlationId default uuid())
    ++ "\nHTTP Status:    "
    ++ ((errResp.statusCode default vars.httpStatus default 500) as String)
    ++ "\nStatus Message: "
    ++ errorTypeValue
    ++ "\nTimestamp:      "
    ++ (errResp.timestamp default (now() as String {format: "yyyy-MM-dd HH:mm:ss"}))

var message =
    if (errorCategory == "AZURE_CONNECTIVITY")
        "Failed to "
        ++ azureOperation
        ++ " Azure Blob Storage"
        ++ (
            if (rawErrNs == "AZURE-STORAGE")
                " — the Azure Storage connector returned an error."
            else
                ". Error: " ++ rawErrId ++ "."
        )
    else if (errorCategory == "APIKIT")
        "An invalid request was received by the B2B Payload Storage API. Reason: "
        ++ rawErrId
        ++ "."
    else
        "An unexpected error occurred in the B2B Payload Storage API. Error: "
        ++ rawErrNs
        ++ ":"
        ++ rawErrId
        ++ "."

var data = {
    documentType: "B2B Payload Storage API",
    appName: p("api.name") default "b2b-payload-storage-api",
    environment: upper(safe(sysInfo.env, p("mule.env"))),
    errorTitle: errorTitle,
    bannerColor: bannerColor,
    errorType: errorTypeValue,
    errorCategory: errorCategory,
    status: "FAILED",
    message: message,
    errorResolution: errorResolution,
    errorDescription: errorDescFull,
    timestamp: errResp.timestamp default (now() as String {format: "yyyy-MM-dd HH:mm:ss"})
}

var template =
    readUrl(
        "classpath://templates/error-template-payloadStorage-api.html",
        "text/plain"
    )

---
template replace /\$\{(\w+)\}/ with ((m) ->
    (data[m[1]] as String) default ""
)