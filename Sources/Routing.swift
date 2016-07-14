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
public protocol RouteNavigator: CustomStringConvertible {
	
	func findHandler(uri: String, webResponse: HTTPResponse) -> RequestHandler?
}

public struct Route {
	let method: HTTPMethod
	let uri: String
	let handler: RequestHandler
}

public struct Routes {
	var routes = [Route]()
	let baseUri: String
	
	public init() {
		self.baseUri = ""
	}
	public init(baseUri: String) {
		self.baseUri = Routes.sanitizeUri(baseUri)
	}
	
	public mutating func add(routes: Routes) {
		for route in routes.routes {
			self.add(route)
		}
	}
	
	public mutating func add(_ route: Route) {
		routes.append(Route(method: route.method, uri: self.baseUri + Routes.sanitizeUri(route.uri), handler: route.handler))
	}
	
	public mutating func add(method: HTTPMethod, uri: String, handler: RequestHandler) {
		self.add(Route(method: method, uri: self.baseUri + Routes.sanitizeUri(uri), handler: handler))
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
		
		func findHandler(uri: String, webResponse: HTTPResponse) -> RequestHandler? {
			let components = uri.lowercased().routePathComponents
			let g = components.makeIterator()
			let method = webResponse.request.method
			guard let root = self.map[method] else {
				return nil
			}
			guard let handler = root.findHandler(currentComponent: "", generator: g, webResponse: webResponse) else {
				return nil
			}
			return handler
		}
	}
	
	private func formatException(route r: String, error: ErrorProtocol) -> String {
		return "\(error) - \(r)"
	}
	
	public var navigator: RouteNavigator {
		var map = [HTTPMethod:RouteNode]()
		for route in routes {
			let method = route.method
			let uri = route.uri
			let handler = route.handler
			
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
		return Navigator(map: map)
	}
}

extension String {
	var routePathComponents: [String] {
		let components = self.characters.split(separator: "/").map(String.init)
		return components
	}
}

private enum RouteException: ErrorProtocol {
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
	
	func findHandler(currentComponent curComp: String, generator: ComponentGenerator, webResponse: HTTPResponse) -> RouteMap.RequestHandler? {
		var m = generator
		if let p = m.next() where p != "/" {
			
			// variables
			for node in self.variables {
				if let h = node.findHandler(currentComponent: p, generator: m, webResponse: webResponse) {
					return self.successfulRoute(currentComponent: curComp, handler: node.successfulRoute(currentComponent: p, handler: h, webResponse: webResponse), webResponse: webResponse)
				}
			}
			
			// paths
			if let node = self.subNodes[p] {
				if let h = node.findHandler(currentComponent: p, generator: m, webResponse: webResponse) {
					return self.successfulRoute(currentComponent: curComp, handler: node.successfulRoute(currentComponent: p, handler: h, webResponse: webResponse), webResponse: webResponse)
				}
			}
			
			// wildcard
			if let node = self.wildCard {
				if let h = node.findHandler(currentComponent: p, generator: m, webResponse: webResponse) {
					return self.successfulRoute(currentComponent: curComp, handler: node.successfulRoute(currentComponent: p, handler: h, webResponse: webResponse), webResponse: webResponse)
				}
			}
			
			// trailing wildcard
			if let node = self.trailingWildCard {
				if let h = node.findHandler(currentComponent: p, generator: m, webResponse: webResponse) {
					return self.successfulRoute(currentComponent: curComp, handler: node.successfulRoute(currentComponent: p, handler: h, webResponse: webResponse), webResponse: webResponse)
				}
			}
			
		} else if self.handler != nil {
			
			return self.handler
			
		} else {
			// wildcards
			if let node = self.wildCard {
				if let h = node.findHandler(currentComponent: "", generator: m, webResponse: webResponse) {
					return self.successfulRoute(currentComponent: curComp, handler: node.successfulRoute(currentComponent: "", handler: h, webResponse: webResponse), webResponse: webResponse)
				}
			}
			
			// trailing wildcard
			if let node = self.trailingWildCard {
				if let h = node.findHandler(currentComponent: "", generator: m, webResponse: webResponse) {
					return self.successfulRoute(currentComponent: curComp, handler: node.successfulRoute(currentComponent: "", handler: h, webResponse: webResponse), webResponse: webResponse)
				}
			}
		}
		return nil
	}
	
	func successfulRoute(currentComponent _: String, handler: RouteMap.RequestHandler, webResponse: HTTPResponse) -> RouteMap.RequestHandler {
		return handler
	}
	
	func addPathSegments(generator gen: ComponentGenerator, handler: RouteMap.RequestHandler) throws {
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
	
	private func addPathSegment(component comp: String, g: ComponentGenerator, h: RouteMap.RequestHandler) throws {
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
	
	override func addPathSegments(generator gen: ComponentGenerator, handler: RouteMap.RequestHandler) throws {
		var m = gen
		if let _ = m.next() {
			throw RouteException.invalidRoute
		} else {
			self.handler = handler
		}
	}
	
	override func findHandler(currentComponent curComp: String, generator: ComponentGenerator, webResponse: HTTPResponse) -> RouteMap.RequestHandler? {
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
	
	override func successfulRoute(currentComponent currComp: String, handler: RouteMap.RequestHandler, webResponse: HTTPResponse) -> RouteMap.RequestHandler {
		let request = webResponse.request
		if let decodedComponent = currComp.stringByDecodingURL {
			request.urlVariables[self.name] = decodedComponent
		} else {
			request.urlVariables[self.name] = currComp
		}
		return handler
	}
}

// -- old --

// for compatability only
var compatRoutes = Routes()

// Holds the registered routes.
@available(*, deprecated, message: "Use new Routes API instead")
public struct RouteMap: CustomStringConvertible {

	public typealias RequestHandler = (HTTPRequest, HTTPResponse) -> ()

	public var description: String {
		return compatRoutes.navigator.description
	}
	
	public subscript(path: String) -> RequestHandler? {
		get {
			return nil // Swift does not currently allow set-only subscripts
		}
		set {
			guard let handler = newValue else {
				return
			}
            compatRoutes.add(method: .get, uri: path, handler: handler)
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
			compatRoutes.add(method: method, uri: path, handler: handler)
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
