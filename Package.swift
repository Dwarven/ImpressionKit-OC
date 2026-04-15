// swift-tools-version: 5.9
//
// MIT License
//
// Copyright (c) 2025 Dwarven Yang <prison.yang@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import PackageDescription

let package = Package(
    name: "ImpressionKit-OC",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(name: "ImpressionKit-OC", targets: ["ImpressionKit-OC"]),
        .library(name: "ImpressionKit-OC-Dynamic", type: .dynamic, targets: ["ImpressionKit-OC"]),
        .library(name: "ImpressionKit-OC-SwiftUI", targets: ["ImpressionKit-OC-SwiftUI"]),
        .library(name: "ImpressionKit-OC-SwiftUI-Dynamic", type: .dynamic, targets: ["ImpressionKit-OC-SwiftUI"])
    ],
    targets: [
        .target(
            name: "ImpressionKit-OC",
            path: "ImpressionKit-OC",
            exclude: [],
            sources: [
                "ImpkGroup.h",
                "ImpkGroup.m",
                "UIView+Impk.h",
                "UIView+Impk.m"
            ],
            resources: [.copy("PrivacyInfo.xcprivacy")],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath(".")
            ]
        ),
        .target(
            name: "ImpressionKit-OC-SwiftUI",
            dependencies: ["ImpressionKit-OC"],
            path: "ImpressionKit-OC",
            sources: [
                "Impk+ViewModifier.swift"
            ]
        )
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
