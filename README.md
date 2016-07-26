# Perfect-HTTP
Base HTTP Support for Perfect

[![GitHub version](https://badge.fury.io/gh/PerfectlySoft%2FPerfect-HTTP.svg)](https://badge.fury.io/gh/PerfectlySoft%2FPerfect-HTTP)

This repository is an indirect dependency for the Perfect HTTP 1.1 and FastCGI servers. You should not need to add it as a direct dependency in your projects. Please look at [Perfect HTTPServer](https://github.com/PerfectlySoft/Perfect-HTTPServer) for more details.

## What its for:
The HTTP library provides a set of Enums, Structs, Objects and methods to handle interactions with http clients. When you are setting up an HTTPServer or FastCGI plugin, you will need to import this library to use the Routing functions.

```
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
```

An example of a routing declaration using a closure block as the handler: 

```
var routes = Routes()

routes.add(method: .get, uri: "/", handler: {
		request, response in
		response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
		response.completed()
	}
)
```

The handler can be a separate function which takes an HTTPRequest, an HTTPResponse and either completes the response or hands off to a function which does.

```
routes.add(method: .get, uri: "/hello", handler: helloWorld)

public func helloWorld(_ request: HTTPRequest, response: HTTPResponse) {
    response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
	response.completed()
}
```

The routes must be added to the server instance before it is started.

```
let server = HTTPServer()

server.addRoutes(routes)
configureServer(server)
```
The addRoutes function can be called several times to add more routes if needed. Routes can not be added or modified after a server has started listening for requests.

```
do {
	// Launch the HTTP server.
	try server.start()
    
} catch PerfectError.networkError(let err, let msg) {
	print("Network error thrown: \(err) \(msg)")
}

```

Inside your handler function, the HTTPRequest object provides access to all client request information. This includes all  client headers, query parameters, POST body data and other relevant information such as the client IP address and URL variables.

HTTPRequest will handle parsing and decoding all "application/x-www-form-urlencoded" as well as "multipart/form-data" content type requests. It will make the data for any other content types available in a raw, unparsed form. When handling multipart form data, HTTPRequest will automatically decode the data and create temporary files for any file uploads contained therein. These files will exist until the request ends after which they will be automatically deleted.

As you build the return values, the HTTPResponse object contains all outgoing response data. This consists of the HTTP status code and message, the HTTP headers and any response body data. HTTPResponse also contains the ability to stream or push chunks of response data to the client and to complete or terminate the request.
