# Perfect-HTTP [简体中文](README.zh_CN.md)

<p align="center">
    <a href="http://perfect.org/get-involved.html" target="_blank">
        <img src="http://perfect.org/assets/github/perfect_github_2_0_0.jpg" alt="Get Involed with Perfect!" width="854" />
    </a>
</p>

<p align="center">
    <a href="https://github.com/PerfectlySoft/Perfect" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_1_Star.jpg" alt="Star Perfect On Github" />
    </a>  
    <a href="http://stackoverflow.com/questions/tagged/perfect" target="_blank">
        <img src="http://www.perfect.org/github/perfect_gh_button_2_SO.jpg" alt="Stack Overflow" />
    </a>  
    <a href="https://twitter.com/perfectlysoft" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_3_twit.jpg" alt="Follow Perfect on Twitter" />
    </a>  
    <a href="http://perfect.ly" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_4_slack.jpg" alt="Join the Perfect Slack" />
    </a>
</p>

<p align="center">
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat" alt="Swift 4.0">
    </a>
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Platforms-OS%20X%20%7C%20Linux%20-lightgray.svg?style=flat" alt="Platforms OS X | Linux">
    </a>
    <a href="http://perfect.org/licensing.html" target="_blank">
        <img src="https://img.shields.io/badge/License-Apache-lightgrey.svg?style=flat" alt="License Apache">
    </a>
    <a href="http://twitter.com/PerfectlySoft" target="_blank">
        <img src="https://img.shields.io/badge/Twitter-@PerfectlySoft-blue.svg?style=flat" alt="PerfectlySoft Twitter">
    </a>
    <a href="http://perfect.ly" target="_blank">
        <img src="http://perfect.ly/badge.svg" alt="Slack Status">
    </a>
</p>

# Base HTTP Support for Perfect

This repository is a dependency for the Perfect HTTP/1, HTTP/2, and FastCGI servers. Please look at [Perfect HTTPServer](https://github.com/PerfectlySoft/Perfect-HTTPServer) for more details.

## Overview

The HTTP library provides a set of Enums, Structs, Protocols and functions to handle interactions with HTTP clients. It provides concrete implimentations for the URL routing mechanism. When you are setting up an HTTPServer you will need to import this library to use the Routing functions. Generally:

``` swift
import PerfectHTTP
import PerfectHTTPServer
```

An example of a routing declaration using a closure block as the handler: 

``` swift
var routes = Routes()
routes.add(method: .get, uri: "/") {
	request, response in
	response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
	response.completed()
}
```

The handler can be a separate function which takes an HTTPRequest, an HTTPResponse and either completes the response or hands off to a function which does.

``` swift
func helloWorld(request: HTTPRequest, response: HTTPResponse) {
	response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
		.completed()
}
routes.add(method: .get, uri: "/hello", handler: helloWorld)
```

The routes must be added to the server instance before it is started.

``` swift
try HTTPServer.launch(name: "my.server.ca", port: port, routes: routes)
```

Routes can not be added or modified after a server has started listening for requests.

Inside your handler function the HTTPRequest object provides access to all client request information. This includes all  client headers, query parameters, POST body data and other relevant information such as the client IP address and URL variables.

HTTPRequest will handle parsing and decoding all "application/x-www-form-urlencoded" as well as "multipart/form-data" content type requests. It will make the data for any other content types available in a raw, unparsed form. When handling multipart form data, HTTPRequest will automatically decode the data and create temporary files for any file uploads contained therein. These files will exist until the request ends after which they will be automatically deleted.

As you build the return values, the HTTPResponse object contains all outgoing response data. This consists of the HTTP status code and message, the HTTP headers, and any response body data. HTTPResponse also contains the ability to stream or push chunks of response data to the client and to complete or terminate the request.

### <a name="typed"></a>Typed Routing

In addition to raw handlers which accept request and response objects, Perfect-HTTP routes also support strongly typed handlers which decode, accept, or return Codable Swift objects.

The APIs for working with typed routes are very similar to those for working with un-typed routes. The objects for producing typed routes are named `TRoutes` and `TRoute`. The meaning and usage of these objects correspond closely to those of the `Routes` and `Route` objects, respectively. 

The interfaces for these objects are as follows:

```swift
/// A typed intermediate route handler parameterized on the input and output types.
public struct TRoutes<I, O> {
	/// Input type alias
	public typealias InputType = I
	/// Output type alias
	public typealias OutputType = O
	/// Init with a base URI and handler.
	public init(
		baseUri u: String,
		handler t: @escaping (InputType) throws -> OutputType)
	/// Add a typed route to this base URI.
	@discardableResult
	public mutating func add<N>(_ route: TRoute<OutputType, N>) -> TRoutes
	/// Add other intermediate routes to this base URI.
	@discardableResult
	public mutating func add<N>(_ route: TRoutes<OutputType, N>) -> TRoutes
	/// Add a route to this object. The new route will take the output of this route as its input.
	@discardableResult
	public mutating func add<N: Codable>(
		method m: HTTPMethod,
		uri u: String,
		handler t: @escaping (OutputType) throws -> N) -> TRoutes
}

/// A typed route handler.
public struct TRoute<I, O: Codable> {
	/// Input type alias.
	public typealias InputType = I
	/// Output type alias.
	public typealias OutputType = O
	// Init with a method, uri, and handler.
	public init(
		method m: HTTPMethod,
		uri u: String,
		handler t: @escaping (InputType) throws -> OutputType)
	/// Init with zero or more methods, a uri, and handler.
	public init(
		methods m: [HTTPMethod] = [.get, .post],
		uri u: String,
		handler t: @escaping (InputType) throws -> OutputType)
}
```

Just as with `Routes` and `Route` objects, a `TRoutes` is an intermediate handler and a `TRoute` is a terminal handler.

A `TRoutes` handler can be created accepting either an HTTPRequest object or any other type of object which may be passed down from a previous handler. The first `TRoutes` handler is usually created accepting the HTTPRequest object. This handler in turn processes its input and returns some object which is given to subsequent handlers.

A `TRoute` handler accepts some sort of input type and returns a Codable object. This codable object is serialized to JSON and returned to the client.

The input to both types of handlers will either be the HTTPRequest, the result of decoding the request body to some Decodable object, or the return value of whatever intermediate handler occurred immediately before. When a handler is defined as receiving a Decodable object, the HTTPRequest body will be automatically decoded into this type. If the body can not be decoded then an Error will be thrown and the error response will be returned to the client. Alternatively, a handler can be defined as accepting the HTTPRequest object but can decode the body itself using the `HTTPRequest.decode` function (described below).

#### Request Body Decode

Two extensions on the HTTPRequest object aid in decoding the request body. 

```swift
/// Extensions on HTTPRequest which permit the request body to be decoded to a Codable type.
public extension HTTPRequest {
	/// Decode the request as the desired object.
	func decode<A: Codable>() throws -> A
	/// Identity decode. Used to permit generic code to operate with the HTTPRequest
	func decode() throws -> Self
}
```

The first function will decode the body into the desired Codable object. If the request's content-type is application/json then the body will be decoded from that JSON. Otherwise, the request's URL encoded GET or POST arguments will be used for the decode. Additionally, any URL variables (described later in this document) will be utilized for the decode. This allows for a mixture of GET/POST arguments and URL variables to be brought together when decoding the object.

Note that when decoding objects from non-JSON request data, nested, non-integral objects are not supported. Objects with array properties are also not supported in this case. 

#### Response Error

If either an intermediate or terminal typed handler experiences an error during processing, they can throw an `HTTPResponseError`. Initializing one of these objects requires both an `HTTPResponseStatus` and a String description of the problem. 

```swift
/// A codable response type indicating an error.
public struct HTTPResponseError: Error, Codable, CustomStringConvertible {
	/// The HTTP status for the response.
	public let status: HTTPResponseStatus
	/// Textual description of the error.
	public let description: String
	/// Init with status and description.
	public init(
		status s: HTTPResponseStatus,
		description d: String)
}
```

#### Support Extensions

Extensions on `Routes` permits adding `TRoutes` or `TRoute` objects.

```swift
public extension Routes {
	/// Add routes to this object.
	mutating func add<I, O>(_ route: TRoutes<I, O>)
	/// Add a route to this object.
	mutating func add<I, O>(_ route: TRoute<I, O>)
}
```

#### <a name="typed_examples"></a>Typed Routing Examples

The following example shows how Codable objects for a route would be defined and how the typed routes would be added to a `Routes` object.

In this abbreviated example the intermediate handler for "/api" would perform some screening on the request to ensure the client has been authenticated. It would then return to the next handler (which is terminal, in this case) a tuple consisting of the original HTTPRequest object as well as a `SessionInfo` object containing whatever client id had been pulled from the request. The terminal handler "/api/info/{id}" would then use this information to complete the request and return the response.

```swift
struct SessionInfo: Codable {
	//...could be an authentication token, etc.
	let id: String
}
struct RequestResponse: Codable {
	struct Address: Codable {
		let street: String
		let city: String
		let province: String
		let country: String
		let postalCode: String
	}
	let fullName: String
	let address: Address
}
// when handlers further down need the request you can pass it along. this is not necessary though
typealias RequestSession = (request: HTTPRequest, session: SessionInfo)

// intermediate handler for /api
func checkSession(request: HTTPRequest) throws -> RequestSession {
	// one would check the request to make sure it's authorized
	let sessionInfo: SessionInfo = try request.decode() // will throw if request does not include id
	return (request, sessionInfo)
}

// terminal handler for /api/info/{id}
func userInfo(session: RequestSession) throws -> RequestResponse {
	// return the response for this request
	return .init(fullName: "Justin Trudeau",
		address: .init(
			street: "111 Wellington St",
			city: "Ottawa",
			province: "Ontario",
			country: "Canada",
			postalCode: "K1A 0A6"))
}
// root Routes object holding all other routes for this server
var routes = Routes()
// types routes object for the /api URI
var apiRoutes = TRoutes(baseUri: "/api", handler: checkSession)
// add terminal handler for the /info/{id} URI suffix
apiRoutes.add(method: .get, uri: "/info/{id}", handler: userInfo)
// add the typed routes to the root
routes.add(apiRoutes)

// add routes to server and launch
try HTTPServer.launch(name: "my.server.ca", port: port, routes: routes)
```

## More Information

The following documents contain pertinent information:

[Configuring and Launching HTTPServer](https://www.perfect.org/docs/HTTPServer.html)

[Routing](https://www.perfect.org/docs/routing.html)

[All Perfect Docs](https://www.perfect.org/docs/)
