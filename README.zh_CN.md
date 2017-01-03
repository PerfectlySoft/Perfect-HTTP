# Perfect-HTTP [English](README.md)

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

## 问题报告

目前我们已经把所有错误报告合并转移到了JIRA上，因此github原有的错误汇报功能不能用于本项目。

您的任何宝贵建意见或建议，或者发现我们的程序有问题，欢迎您在这里告诉我们。http://jira.perfect.org:8080/servicedesk/customer/portal/1。

问题清单请参考以下链接：http://jira.perfect.org:8080/projects/ISS/issues。

======

该项目是 Perfect HTTP 和 FastCGI 服务器的间接依赖库。请不要在你的项目中直接添加该依赖库。详细内容请查看 [Perfect HTTPServer](https://github.com/PerfectlySoft/Perfect-HTTPServer)。

## 应用场景：
该 HTTP 库为处理与 http 客户端的交互提供了一系列枚举，结构体，对象和方法。当设置 HTTPServer 或者 PastCGI 插件时，为了使用路由相关方法您需要导入该库。

``` swift
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
```

下面是使用闭包作为句柄的路由声明：

``` swift
var routes = Routes()

routes.add(method: .get, uri: "/", handler: {
		request, response in
		response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
		response.completed()
	}
)
```

该句柄可以作为一个接收 HTTPRequest，HTTPResponse 和处理响应句柄等参数的独立方法。

``` swift
routes.add(method: .get, uri: "/hello", handler: helloWorld)

public func helloWorld(_ request: HTTPRequest, response: HTTPResponse) {
    response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
	response.completed()
}
```

路由必须在服务器启动之前添加到服务器实例对象中。

``` swift
let server = HTTPServer()

server.addRoutes(routes)
configureServer(server)
```

addRoutes 可多次调用来添加多个路由。在服务器启动开始监听请求后就无法再添加或者修改路由。

``` swift
do {
	// 启动服务器
	try server.start()
    
} catch PerfectError.networkError(let err, let msg) {
	print("Network error thrown: \(err) \(msg)")
}

```

在句柄方法中，通过 HTTPRequest 对象可访问到客户端网络请求的所有信息。这些信息包括请求头，查询参数，POST 请求的 body 数据和客户端 IP 地址，URL 参数等相关信息。

HTTPRequest 用于解码 "application/x-www-form-urlencoded" 和 "multipart/form-data" 编码方式的请求。HTTPRequest 会将数据解析为原始的可用类型的数据。当处理 multipart form 类型的数据时，HTTPRequest 会自动自动解码数据并为网络请求中包含的上传数据建立一个临时文件。这些临时文件在请求完成后会自动删除。

当构建好返回数据，HTTPResponse 对象包含所有的响应数据。这些响应数据包括 HTTP 状态码，消息体，HTTP 消息头和响应体数据。HTTPResponse 同时也包括了流化，推送响应数据到客户端，完成或终止请求的能力。

=======

该项目是 Perfect HTTP 和 FastCGI 服务器的间接依赖库。请不要在你的项目中直接添加该依赖库。详细内容请查看 [Perfect HTTPServer](https://github.com/PerfectlySoft/Perfect-HTTPServer)。
