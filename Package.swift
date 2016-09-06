import PackageDescription

#if os(Linux)
let package = Package(
	name: "PerfectHTTP",
	targets: [],
	dependencies: [
		.Package(url: "https://github.com/PerfectlySoft/PerfectLib.git", versions: Version(0,0,0)..<Version(10,0,0)),
		.Package(url: "https://github.com/PerfectlySoft/Perfect-Net.git", versions: Version(0,0,0)..<Version(10,0,0)),
		.Package(url: "https://github.com/PerfectlySoft/Perfect-LinuxBridge.git", versions: Version(0,0,0)..<Version(10,0,0))
	],
	exclude: []
)
#else
let package = Package(
	name: "PerfectHTTP",
	targets: [],
	dependencies: [
		.Package(url: "https://github.com/PerfectlySoft/PerfectLib.git", versions: Version(0,0,0)..<Version(10,0,0)),
		.Package(url: "https://github.com/PerfectlySoft/Perfect-Net.git", versions: Version(0,0,0)..<Version(10,0,0))
	],
	exclude: []
)
#endif
