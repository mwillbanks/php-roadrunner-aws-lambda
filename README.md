# aws-lambda
AWS Lambda RR example with latest dependencies in both `go` and `composer`

## Test Procedure

### Setup

```
cd public
composer install
cd -
```

### Download aws-lambda-rie (macOS)

```
mkdir -p ~/.aws-lambda-rie
curl -Lo ~/.aws-lambda-rie/aws-lambda-rie https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-arm64
chmod +x ~/.aws-lambda-rie/aws-lambda-rie
```

### Build the container

```
docker build -t roadrunner-aws-lambda -f Dockerfile --platform linux/arm64 .
```

## Run the Container with AWS Lambda RIE

```
docker run --rm -p 9000:8080 \
  -v /tmp/aws-lambda-rie:/aws-lambda-rie \
  --entrypoint /aws-lambda-rie \
  roadrunner-aws-lambda:latest \
  /var/task/bootstrap
```

## Execute API Gateway Payload

```
curl -s \
  -H "Content-Type: application/json" \
  -d @- \
  http://127.0.0.1:9000/2015-03-31/functions/function/invocations <<'JSON'
{
  "version": "2.0",
  "routeKey": "$default",
  "rawPath": "/",
  "rawQueryString": "",
  "headers": {
    "accept": "text/html,application/xhtml+xml",
    "accept-encoding": "gzip, deflate, br, zstd",
    "host": "local.test",
    "user-agent": "curl/8.5.0",
    "x-forwarded-for": "127.0.0.1",
    "x-forwarded-port": "443",
    "x-forwarded-proto": "https"
  },
  "requestContext": {
    "accountId": "000000000000",
    "apiId": "local",
    "domainName": "local.test",
    "domainPrefix": "local",
    "http": {
      "method": "GET",
      "path": "/",
      "protocol": "HTTP/1.1",
      "sourceIp": "127.0.0.1",
      "userAgent": "curl/8.5.0"
    },
    "requestId": "local-test-request",
    "routeKey": "$default",
    "stage": "$default",
    "time": "03/Dec/2025:19:30:00 +0000",
    "timeEpoch": 1764780600000
  },
  "isBase64Encoded": false,
  "body": null,
  "cookies": []
}
JSON
```

### Result

#### Server Log
```
04 Dec 2025 14:21:06,156 [INFO] (rapid) exec '/var/task/bootstrap' (cwd=/var/task, handler=)
04 Dec 2025 14:21:10,109 [INFO] (rapid) INIT START(type: on-demand, phase: init)
04 Dec 2025 14:21:10,109 [INFO] (rapid) The extension's directory "/opt/extensions" does not exist, assuming no extensions to be loaded.
04 Dec 2025 14:21:10,109 [INFO] (rapid) Starting runtime without AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN , Expected?: false
START RequestId: f594573d-e525-4dbb-8245-e7d683ebffd0 Version: $LATEST
04 Dec 2025 14:21:10,153 [INFO] (rapid) INIT RTDONE(status: success)
04 Dec 2025 14:21:10,153 [INFO] (rapid) INIT REPORT(durationMs: 44.651000)
04 Dec 2025 14:21:10,153 [INFO] (rapid) INVOKE START(requestId: ebdcab85-2c32-4169-a270-f037ff5443ae)
04 Dec 2025 14:21:10,158 [INFO] (rapid) INVOKE RTDONE(status: success, produced bytes: 0, duration: 4.951000ms)
END RequestId: ebdcab85-2c32-4169-a270-f037ff5443ae
REPORT RequestId: ebdcab85-2c32-4169-a270-f037ff5443ae  Init Duration: 0.08 ms  Duration: 49.74 ms      Billed Duration: 50 ms  Memory Size: 3008 MB    Max Memory Used: 3008 MB
```

#### Request Response
```
{"statusCode":500,"headers":null,"multiValueHeaders":null,"body":"","cookies":null}
```