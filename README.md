# Perfect-HTTP
Base HTTP Support for Perfect

[![GitHub version](https://badge.fury.io/gh/PerfectlySoft%2FPerfect-HTTP.svg)](https://badge.fury.io/gh/PerfectlySoft%2FPerfect-HTTP)

This repository is an indirect dependency for the Perfect HTTP 1.1 and FastCGI servers. You should not need to add it as a direct dependency in your projects. Please look at [Perfect](https://github.com/PerfectlySoft/Perfect) for more details.

## HTTPRequest and HTTPResponse

When handling a request, all client interaction is performed through the provided HTTPRequest and HTTPResponse objects. 

The HTTPRequest object makes available all client headers, query parameters, POST body data and other relevant information such as the client IP address and URL variables.

HTTPRequest will handle parsing and decoding all "application/x-www-form-urlencoded" as well as "multipart/form-data" content type requests. It will make the data for any other content types available in a raw, unparsed form. When handling multipart form data, HTTPRequest will automatically decode the data and create temporary files for any file uploads contained therein. These files will exist until the request ends after which they will be automatically deleted.

The HTTPResponse object contains all outgoing response data. This consists of the HTTP status code and message, the HTTP headers and any response body data. HTTPResponse also contains the ability to stream or push chunks of response data to the client and to complete or terminate the request.

## Routing

Routing, in Perfect, refers to the act of directing a request to its proper handler. Requests are routed based on two pieces of information: the HTTP request method and the request path. A route refers to a HTTP method, path and handler combination. Routes are created and added to the server before it starts listening for connections. This can be called several times to add more routes if needed. Routes can not be added or modified after a server has started listening for requests.

```
var routes = Routes()
routes.add(method: .get, uri: "/path/one", handler: { request, response in
    response.setBody(string: "Handler was called")
    response.completed()
})
server.addRoutes(routes)
```

Before adding a route you will need an appropriate handler function. Handler functions accept the request and response objects and are expected to generate content for the response and indicate when they have completed the task. To be clear, than handler in the initial example which is provided as a closure, can also be defined as a separate function. The typealias for a request handler is as follows:

```
/// Function which receives request and response objects and generates content.
public typealias RequestHandler = (HTTPRequest, HTTPResponse) -> ()
```

