//
//  Routing.swift
//  PerfectLib
//
//  Created by Kyle Jessup on 2015-12-11.
//  Copyright © 2015 PerfectlySoft. All rights reserved.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib

/// Function which receives request and response objects and generates content.
public typealias RequestHandler = (HTTPRequest, HTTPResponse) -> ()

/// Object which maps uris to handler.
/// RouteNavigators are given to the HTTPServer to control its content generation.
public protocol RouteNavigator: CustomStringConvertible {
	// Given a URI and HTTPRequest, return the handler or nil if there was none.
	func findHandler(uri: String, webRequest: HTTPRequest) -> RequestHandler?
}

// The url variable key under which the remaining path in a trailing wild card will be placed.
public let routeTrailingWildcardKey = "_trailing_wildcard_"

/// Combines a method, uri and handler
public struct Route {
	public let methods: [HTTPMethod]
	public let uri: String
	public let handler: RequestHandler
	/// A single method, a uri and handler.
	public init(method: HTTPMethod, uri: String, handler: @escaping RequestHandler) {
		self.methods = [method]
		self.uri = uri
		self.handler = handler
	}
	/// An array of methods, a uri and handler.
	public init(methods: [HTTPMethod], uri: String, handler: @escaping RequestHandler) {
		self.methods = methods
		self.uri = uri
		self.handler = handler
	}
	/// A uri and a handler on any method.
	public init(uri: String, handler: @escaping RequestHandler) {
		self.methods = HTTPMethod.allMethods
		self.uri = uri
		self.handler = handler
	}
}

/// A group of routes. Add one or more routes to this object then call its navigator property to get the RouteNavigator.
/// Can be created with a baseUri. All routes which are added will have their URIs prefixed with this value.
public struct Routes {
	var routes = [Route]()
	let baseUri: String
	
	/// Initialize with no baseUri.
	public init() {
		self.baseUri = ""
	}
	
	/// Initialize with a baseUri.
	public init(baseUri: String) {
		self.baseUri = Routes.sanitizeUri(baseUri)
	}
	
	/// Initialize with a array of Route.
	public init(_ routes: [Route]) {
		self.baseUri = ""
		add(routes)
	}
	
	/// Initialize with a baseUri and array of Route.
	public init(baseUri: String, routes: [Route]) {
		self.baseUri = Routes.sanitizeUri(baseUri)
		add(routes)
	}
	
	// Add all the routes in the Routes object to this one.
	@available(*, deprecated, message: "Use Routes.add(_:Routes)")
	public mutating func add(routes: Routes) {
		for route in routes.routes {
			self.add(route)
		}
	}
	
	/// Add all the routes in the Routes object to this one.
	public mutating func add(_ routes: Routes) {
		for route in routes.routes {
			self.add(route)
		}
	}
	
	/// Add all the routes in the Routes array to this one.
	public mutating func add(_ routes: [Route]) {
		for route in routes {
			self.add(route)
		}
	}
	
	/// Add one Route to this object.
	public mutating func add(_ route: Route, routes vroots: Route...) {
		routes.append(Route(methods: route.methods, uri: self.baseUri + Routes.sanitizeUri(route.uri), handler: route.handler))
		add(vroots)
	}
	
	/// Add the given method, uri and handler as a route.
	public mutating func add(method: HTTPMethod, uri: String, handler: @escaping RequestHandler) {
		add(Route(method: method, uri: uri, handler: handler))
	}
	
	/// Add the given method, uris and handler as a route.
	public mutating func add(method: HTTPMethod, uris: [String], handler: @escaping RequestHandler) {
		for uri in uris {
			add(method: method, uri: uri, handler: handler)
		}
	}
	
	/// Add the given uri and handler as a route. 
	/// This will add the route for all standard methods.
	public mutating func add(uri: String, handler: @escaping RequestHandler) {
		add(Route(uri: uri, handler: handler))
	}
	
	/// Add the given method, uris and handler as a route.
	/// This will add the route for all standard methods.
	public mutating func add(uris: [String], handler: @escaping RequestHandler) {
		for uri in uris {
			add(uri: uri, handler: handler)
		}
	}
	
	static func sanitizeUri(_ uri: String) -> String {
		let split = uri.characters.split(separator: "/").map(String.init)
		return "/" + split.joined(separator: "/")
	}
	
	struct Navigator: RouteNavigator {
		let map: [HTTPMethod:RouteNode]
		
		var description: String {
			var s = ""
			for (method, root) in self.map {
				s.append("\n\(method):\n\(root.description)")
			}
			return s
		}
		
		func findHandler(uri: String, webRequest: HTTPRequest) -> RequestHandler? {
			let components = uri.routePathComponents
			let g = components.makeIterator()
			let method = webRequest.method
			guard let root = self.map[method] else {
				return nil
			}
			guard let handler = root.findHandler(currentComponent: "", generator: g, webRequest: webRequest) else {
				return nil
			}
			return handler
		}
	}
	
	private func formatException(route r: String, error: Error) -> String {
		return "\(error) - \(r)"
	}
	
	/// Return the RouteNavigator for this object.
	public var navigator: RouteNavigator {
		var map = [HTTPMethod:RouteNode]()
		for route in routes {
			let uri = route.uri
			let handler = route.handler
			for method in route.methods {
				var fnd = map[method]
				if nil == fnd {
					fnd = RouteNode()
					map[method] = fnd
				}
				guard let node = fnd else {
					continue
				}
				do {
					try node.addPathSegments(generator: uri.lowercased().routePathComponents.makeIterator(), handler: handler)
				} catch let e {
					Log.error(message: self.formatException(route: uri, error: e))
				}
			}
		}
		return Navigator(map: map)
	}
}

extension String {
	var routePathComponents: [String] {
		let components = self.characters.split(separator: "/").map(String.init)
		return components
	}
}

private enum RouteException: Error {
	case invalidRoute
}

class RouteNode: CustomStringConvertible {
	
	typealias ComponentGenerator = IndexingIterator<[String]>
	
	var handler: RouteMap.RequestHandler?
	var trailingWildCard: RouteNode?
	var wildCard: RouteNode?
	var variables = [RouteNode]()
	var subNodes = [String:RouteNode]()
	
	var description: String {
		return self.descriptionTabbed(0)
	}
	
	private func putTabs(_ count: Int) -> String {
		var s = ""
		for _ in 0..<count {
			s.append("\t")
		}
		return s
	}
	
	func descriptionTabbedInner(_ tabCount: Int) -> String {
		var s = ""
		for (_, node) in self.subNodes {
			s.append("\(self.putTabs(tabCount))\(node.descriptionTabbed(tabCount+1))")
		}
		for node in self.variables {
			s.append("\(self.putTabs(tabCount))\(node.descriptionTabbed(tabCount+1))")
		}
		if let node = self.wildCard {
			s.append("\(self.putTabs(tabCount))\(node.descriptionTabbed(tabCount+1))")
		}
		if let node = self.trailingWildCard {
			s.append("\(self.putTabs(tabCount))\(node.descriptionTabbed(tabCount+1))")
		}
		return s
	}
	
	func descriptionTabbed(_ tabCount: Int) -> String {
		var s = ""
		if let _ = self.handler {
			s.append("/+h\n")
		}
		s.append(self.descriptionTabbedInner(tabCount))
		return s
	}
	
	func findHandler(currentComponent curComp: String, generator: ComponentGenerator, webRequest: HTTPRequest) -> RouteMap.RequestHandler? {
		var m = generator
		if let p = m.next(), p != "/" {
			
			// variables
			for node in self.variables {
				if let h = node.findHandler(currentComponent: p, generator: m, webRequest: webRequest) {
					return self.successfulRoute(currentComponent: curComp, handler: node.successfulRoute(currentComponent: p, handler: h, webRequest: webRequest), webRequest: webRequest)
				}
			}
			
			// paths
			if let node = self.subNodes[p.lowercased()] {
				if let h = node.findHandler(currentComponent: p, generator: m, webRequest: webRequest) {
					return self.successfulRoute(currentComponent: curComp, handler: node.successfulRoute(currentComponent: p, handler: h, webRequest: webRequest), webRequest: webRequest)
				}
			}
			
			// wildcard
			if let node = self.wildCard {
				if let h = node.findHandler(currentComponent: p, generator: m, webRequest: webRequest) {
					return self.successfulRoute(currentComponent: curComp, handler: node.successfulRoute(currentComponent: p, handler: h, webRequest: webRequest), webRequest: webRequest)
				}
			}
			
			// trailing wildcard
			if let node = self.trailingWildCard {
				if let h = node.findHandler(currentComponent: p, generator: m, webRequest: webRequest) {
					return self.successfulRoute(currentComponent: curComp, handler: node.successfulRoute(currentComponent: p, handler: h, webRequest: webRequest), webRequest: webRequest)
				}
			}
			
		} else if self.handler != nil {
			
			return self.handler
			
		} else {
			// wildcards
			if let node = self.wildCard {
				if let h = node.findHandler(currentComponent: "", generator: m, webRequest: webRequest) {
					return self.successfulRoute(currentComponent: curComp, handler: node.successfulRoute(currentComponent: "", handler: h, webRequest: webRequest), webRequest: webRequest)
				}
			}
			
			// trailing wildcard
			if let node = self.trailingWildCard {
				if let h = node.findHandler(currentComponent: "", generator: m, webRequest: webRequest) {
					return self.successfulRoute(currentComponent: curComp, handler: node.successfulRoute(currentComponent: "", handler: h, webRequest: webRequest), webRequest: webRequest)
				}
			}
		}
		return nil
	}
	
	func successfulRoute(currentComponent _: String, handler: @escaping RouteMap.RequestHandler, webRequest: HTTPRequest) -> RouteMap.RequestHandler {
		return handler
	}
	
	func addPathSegments(generator gen: ComponentGenerator, handler: @escaping RouteMap.RequestHandler) throws {
		var m = gen
		if let p = m.next() {
			if p == "/" {
				try self.addPathSegments(generator: m, handler: handler)
			} else {
				try self.addPathSegment(component: p, g: m, h: handler)
			}
		} else {
			self.handler = handler
		}
	}
	
	private func addPathSegment(component comp: String, g: ComponentGenerator, h: @escaping RouteMap.RequestHandler) throws {
		if let node = self.nodeForComponent(component: comp) {
			try node.addPathSegments(generator: g, handler: h)
		} else {
			throw RouteException.invalidRoute
		}
	}
	
	private func nodeForComponent(component comp: String) -> RouteNode? {
		guard !comp.isEmpty else {
			return nil
		}
		if comp == "*" {
			if self.wildCard == nil {
				self.wildCard = RouteWildCard()
			}
			return self.wildCard
		}
		if comp == "**" {
			if self.trailingWildCard == nil {
				self.trailingWildCard = RouteTrailingWildCard()
			}
			return self.trailingWildCard
		}
		if comp.characters.count >= 3 && comp[comp.startIndex] == "{" && comp[comp.index(before: comp.endIndex)] == "}" {
			let node = RouteVariable(name: comp[comp.index(after: comp.startIndex)..<comp.index(before: comp.endIndex)])
			self.variables.append(node)
			return node
		}
		if let node = self.subNodes[comp] {
			return node
		}
		let node = RoutePath(name: comp)
		self.subNodes[comp] = node
		return node
	}
	
}

class RoutePath: RouteNode {
	
	let name: String
	init(name: String) {
		self.name = name
	}
	
	override func descriptionTabbed(_ tabCount: Int) -> String {
		var s = "/\(self.name)"
		
		if let _ = self.handler {
			s.append("+h\n")
		} else {
			s.append("\n")
		}
		s.append(self.descriptionTabbedInner(tabCount))
		return s
	}
	
	// RoutePaths don't need to perform any special checking.
	// Their path is validated by the fact that they exist in their parent's `subNodes` dict.
}

class RouteWildCard: RouteNode {
	
	override func descriptionTabbed(_ tabCount: Int) -> String {
		var s = "/*"
		if let _ = self.handler {
			s.append("+h\n")
		} else {
			s.append("\n")
		}
		s.append(self.descriptionTabbedInner(tabCount))
		return s
	}
}

class RouteTrailingWildCard: RouteWildCard {
	
	override func descriptionTabbed(_ tabCount: Int) -> String {
		var s = "/**"
		if let _ = self.handler {
			s.append("+h\n")
		} else {
			s.append("\n")
		}
		s.append(self.descriptionTabbedInner(tabCount))
		return s
	}
	
	override func addPathSegments(generator gen: ComponentGenerator, handler: @escaping RouteMap.RequestHandler) throws {
		var m = gen
		if let _ = m.next() {
			throw RouteException.invalidRoute
		} else {
			self.handler = handler
		}
	}
	
	override func findHandler(currentComponent curComp: String, generator: ComponentGenerator, webRequest: HTTPRequest) -> RouteMap.RequestHandler? {
		let trailingVar = "/\(curComp)" + generator.map { "/" + $0 }.joined(separator: "")
		webRequest.urlVariables[routeTrailingWildcardKey] = trailingVar
		return self.handler
	}
}

class RouteVariable: RouteNode {
	
	let name: String
	init(name: String) {
		self.name = name
	}
	
	override func descriptionTabbed(_ tabCount: Int) -> String {
		var s = "/{\(self.name)}"
		if let _ = self.handler {
			s.append("+h\n")
		} else {
			s.append("\n")
		}
		s.append(self.descriptionTabbedInner(tabCount))
		return s
	}
	
	override func successfulRoute(currentComponent currComp: String, handler: @escaping RouteMap.RequestHandler, webRequest: HTTPRequest) -> RouteMap.RequestHandler {
		if let decodedComponent = currComp.stringByDecodingURL {
			webRequest.urlVariables[self.name] = decodedComponent
		} else {
			webRequest.urlVariables[self.name] = currComp
		}
		return handler
	}
}

// -- old --
// ALL code below this is obsolete but remains to provide compatability 1.0 based solutions.
// For 1.0 compatability only.
public var compatRoutes: Routes?

// Holds the registered routes.
@available(*, deprecated, message: "Use new Routes API instead")
public struct RouteMap: CustomStringConvertible {

	public typealias RequestHandler = (HTTPRequest, HTTPResponse) -> ()

	public var description: String {
		return compatRoutes?.navigator.description ?? "no routes"
	}
	
	public subscript(path: String) -> RequestHandler? {
		get {
			return nil // Swift does not currently allow set-only subscripts
		}
		set {
			guard let handler = newValue else {
				return
			}
			if nil == compatRoutes {
				compatRoutes = Routes()
			}
            compatRoutes?.add(method: .get, uri: path, handler: handler)
		}
	}

	public subscript(paths: [String]) -> RequestHandler? {
		get {
			return nil
		}
		set {
			for path in paths {
				self[path] = newValue
			}
		}
	}

	public subscript(method: HTTPMethod, path: String) -> RequestHandler? {
		get {
			return nil // Swift does not currently allow set-only subscripts
		}
		set {
			guard let handler = newValue else {
				return
			}
			if nil == compatRoutes {
				compatRoutes = Routes()
			}
			compatRoutes?.add(method: method, uri: path, handler: handler)
		}
	}

	public subscript(method: HTTPMethod, paths: [String]) -> RequestHandler? {
		get {
			return nil // Swift does not currently allow set-only subscripts
		}
		set {
			for path in paths {
				self[method, path] = newValue
			}
		}
	}
}

@available(*, deprecated, message: "Use new Routes API instead")
public struct Routing {
	static public var Routes = RouteMap()
	private init() {}
}
