//===----------------------------------------------------------------------===//
// Copyright © 2026 Apple Inc. and the container project authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//===----------------------------------------------------------------------===//

import ContainerPlugin
import Testing

@testable import ContainerAPIClient

struct ImagelessRuntimeTests {
    struct ConflictCase: Sendable, CustomTestStringConvertible {
        let name: String
        var platform: String? = nil
        var os: String? = nil
        var arch: String? = nil
        var pluginPlatform: String = "darwin/arm64"
        let expected: String?

        var testDescription: String { name }
    }

    static let conflictCases: [ConflictCase] = [
        .init(name: "nothing set", expected: nil),
        .init(name: "equal os and arch", os: "darwin", arch: "arm64", expected: nil),
        .init(name: "arch alias", arch: "aarch64", expected: nil),
        .init(name: "equal platform", platform: "darwin/arm64", expected: nil),
        .init(name: "os conflicts", os: "linux", expected: "runtime mac runs darwin/arm64; --os linux conflicts"),
        .init(name: "arch conflicts", arch: "amd64", expected: "runtime mac runs darwin/arm64; --arch amd64 conflicts"),
        .init(name: "platform os conflicts", platform: "linux/arm64", expected: "runtime mac runs darwin/arm64; --platform linux/arm64 conflicts"),
        .init(name: "platform arch conflicts", platform: "darwin/amd64", expected: "runtime mac runs darwin/arm64; --platform darwin/amd64 conflicts"),
        .init(name: "unparsable platform conflicts", platform: "garbage", expected: "runtime mac runs darwin/arm64; --platform garbage conflicts"),
        .init(name: "flag variant only passes", platform: "darwin/arm64/v8", expected: nil),
        .init(name: "plugin variant only passes", platform: "darwin/arm64", pluginPlatform: "darwin/arm64/v8", expected: nil),
        .init(name: "equal variants pass", platform: "darwin/arm64/v8", pluginPlatform: "darwin/arm64/v8", expected: nil),
        .init(
            name: "different variants conflict", platform: "darwin/arm64/v9", pluginPlatform: "darwin/arm64/v8",
            expected: "runtime mac runs darwin/arm64; --platform darwin/arm64/v9 conflicts"),
        .init(name: "os checked first", os: "linux", arch: "amd64", expected: "runtime mac runs darwin/arm64; --os linux conflicts"),
    ]

    @Test(arguments: conflictCases)
    func platformConflict(_ testCase: ConflictCase) throws {
        let plugin = try #require(PluginConfig.RuntimePlatform(testCase.pluginPlatform))
        let result = Parser.platformConflict(
            runtime: "mac", pluginPlatform: plugin, platform: testCase.platform, os: testCase.os, arch: testCase.arch)
        #expect(result == testCase.expected)
    }

    struct SkipCase: Sendable, CustomTestStringConvertible {
        let name: String
        let runtime: String?
        let config: PluginConfig.RuntimeConfig?
        let expected: Bool

        var testDescription: String { name }
    }

    private static let imageless = PluginConfig.RuntimeConfig(
        requiresKernel: false, requiresInitImage: false, requiresImageSnapshot: false, requiresImage: false, platform: "darwin/arm64")

    static let skipCases: [SkipCase] = [
        .init(name: "explicit runtime that needs no image", runtime: "mac", config: imageless, expected: true),
        .init(name: "nil runtime with requiresImage=false config", runtime: nil, config: imageless, expected: false),
        .init(name: "nil config", runtime: "mac", config: nil, expected: false),
        .init(name: "nil runtime and nil config", runtime: nil, config: nil, expected: false),
        .init(name: "requiresImage true", runtime: "mac", config: .default, expected: false),
    ]

    @Test(arguments: skipCases)
    func skipsImage(_ testCase: SkipCase) {
        #expect(Utility.skipsImage(runtime: testCase.runtime, config: testCase.config) == testCase.expected)
    }
}
