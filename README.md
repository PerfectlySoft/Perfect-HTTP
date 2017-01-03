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
        <img src="https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat" alt="Swift 3.0">
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

Base HTTP Support for Perfect

## Issues

We are transitioning to using JIRA for all bugs and support related issues, therefore the GitHub issues has been disabled.

If you find a mistake, bug, or any other helpful suggestion you'd like to make on the docs please head over to [http://jira.perfect.org:8080/servicedesk/customer/portal/1](http://jira.perfect.org:8080/servicedesk/customer/portal/1) and raise it.

A comprehensive list of open issues can be found at [http://jira.perfect.org:8080/projects/ISS/issues](http://jira.perfect.org:8080/projects/ISS/issues)

======

This repository is an indirect dependency for the Perfect HTTP 1.1 and FastCGI servers. You should not need to add it as a direct dependency in your projects. Please look at [Perfect HTTPServer](https://github.com/PerfectlySoft/Perfect-HTTPServer) for more details.

## What it's for:
The HTTP library provides a set of Enums, Structs, Objects and methods to handle interactions with http clients. When you are setting up an HTTPServer or FastCGI plugin, you will need to import this library to use the Routing functions.

``` swift
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
```

An example of a routing declaration using a closure block as the handler: 

``` swift
var routes = Routes()

routes.add(method: .get, uri: "/", handler: {
		request, response in
		response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
		response.completed()
	}
)
```

The handler can be a separate function which takes an HTTPRequest, an HTTPResponse and either completes the response or hands off to a function which does.

``` swift
routes.add(method: .get, uri: "/hello", handler: helloWorld)

public func helloWorld(_ request: HTTPRequest, response: HTTPResponse) {
    response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
	response.completed()
}
```

The routes must be added to the server instance before it is started.

``` swift
let server = HTTPServer()

server.addRoutes(routes)
configureServer(server)
```
The addRoutes function can be called several times to add more routes if needed. Routes can not be added or modified after a server has started listening for requests.

``` swift
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

=======

This repository is an indirect dependency for the Perfect HTTP 1.1 and FastCGI servers. You should not need to add it as a direct dependency in your projects. Please look at [Perfect](https://github.com/PerfectlySoft/Perfect) for more details.

