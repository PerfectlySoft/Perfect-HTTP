// swift-tools-version:4.0
//
//  Package.swift
//  PerfectHTTP
//
//  Created by Kyle Jessup on 2016-05-02.
//	Copyright (C) 2016 PerfectlySoft, Inc.
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

import PackageDescription

#if os(Linux)
let package = Package(
	name: "PerfectHTTP",
	products: [
		.library(name: "PerfectHTTP", targets: ["PerfectHTTP"])
	],
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/PerfectLib.git", from: "3.0.0"),
		.package(url: "https://github.com/PerfectlySoft/Perfect-Net.git", from: "3.0.0"),
		.package(url: "https://github.com/PerfectlySoft/Perfect-LinuxBridge.git", from: "3.0.0")
	],
 	targets: [
		.target(name: "PerfectHTTP", dependencies: ["PerfectLib", "PerfectNet", "LinuxBridge"]),
		.testTarget(name: "PerfectHTTPTests", dependencies: ["PerfectHTTP", "PerfectNet"])
  ]
)
#else
let package = Package(
	name: "PerfectHTTP",
	products: [
		.library(name: "PerfectHTTP", targets: ["PerfectHTTP"])
	],
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/PerfectLib.git", from: "3.0.0"),
		.package(url: "https://github.com/PerfectlySoft/Perfect-Net.git", from: "3.0.0")
	], targets: [
		.target(name: "PerfectHTTP", dependencies: ["PerfectLib", "PerfectNet"]),
		.testTarget(name: "PerfectHTTPTests", dependencies: ["PerfectHTTP", "PerfectNet"])
  ]
)
#endif
