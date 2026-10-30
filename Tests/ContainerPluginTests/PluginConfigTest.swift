//===----------------------------------------------------------------------===//
// Copyright © 2025-2026 Apple Inc. and the container project authors.
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

import Foundation
import Testing

@testable import ContainerPlugin

struct PluginConfigTest {
    @Test
    func testCLIPluginConfigLoad() async throws {
        let tempURL = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: .temporaryDirectory,
            create: true
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let configURL = tempURL.appending(path: "config.toml")
        let configToml = """
            abstract = "Default network management service"
            author = "Apple"
            """
        try configToml.write(to: configURL, atomically: true, encoding: .utf8)
        let config = try #require(try PluginConfig(configURL: configURL))

        #expect(config.isCLI)
        #expect(config.abstract == "Default network management service")
        #expect(config.author == "Apple")
    }

    @Test
    func testServicePluginConfigLoad() async throws {
        let tempURL = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: .temporaryDirectory,
            create: true
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let configURL = tempURL.appending(path: "config.toml")
        let configToml = """
            abstract = "Default network management service"
            author = "Apple"
            version = 0.1

            [servicesConfig]
            loadAtBoot = true
            runAtLoad = true
            defaultArguments = ["start"]

            [[servicesConfig.services]]
            type = "network"
            description = "foo"
            """
        try configToml.write(to: configURL, atomically: true, encoding: .utf8)
        let config = try #require(try PluginConfig(configURL: configURL))

        #expect(!config.isCLI)
        #expect(config.abstract == "Default network management service")
        #expect(config.author == "Apple")

        let servicesConfig = try #require(config.servicesConfig)
        #expect(servicesConfig.loadAtBoot)
        #expect(servicesConfig.runAtLoad)
        #expect(servicesConfig.services.count == 1)
        #expect(servicesConfig.services[0].type == .network)
        #expect(servicesConfig.services[0].description == "foo")
        #expect(servicesConfig.defaultArguments == ["start"])
    }

    @Test
    func testRuntimeConfigDefaultsWhenOmitted() async throws {
        let tempURL = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: .temporaryDirectory,
            create: true
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let configURL = tempURL.appending(path: "config.toml")
        let configToml = """
            abstract = "Linux container runtime plugin"

            [servicesConfig]
            loadAtBoot = false
            runAtLoad = false
            defaultArguments = []

            [[servicesConfig.services]]
            type = "runtime"
            """
        try configToml.write(to: configURL, atomically: true, encoding: .utf8)
        let config = try #require(try PluginConfig(configURL: configURL))

        #expect(config.runtimeConfig == nil)
        #expect(config.runtimeRequirements == .default)
        #expect(config.runtimeRequirements.requiresKernel)
        #expect(config.runtimeRequirements.requiresInitImage)
        #expect(config.runtimeRequirements.requiresImageSnapshot)
        #expect(config.runtimeRequirements.requiresImage)
        #expect(config.runtimeRequirements.platform == nil)
    }

    @Test
    func testRuntimeConfigLoad() async throws {
        let tempURL = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: .temporaryDirectory,
            create: true
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let configURL = tempURL.appending(path: "config.toml")
        let configToml = """
            abstract = "Example runtime plugin"

            [servicesConfig]
            loadAtBoot = false
            runAtLoad = false
            defaultArguments = []

            [[servicesConfig.services]]
            type = "runtime"

            [runtimeConfig]
            requiresKernel = false
            requiresInitImage = false
            """
        try configToml.write(to: configURL, atomically: true, encoding: .utf8)
        let config = try #require(try PluginConfig(configURL: configURL))

        let runtimeConfig = try #require(config.runtimeConfig)
        #expect(!runtimeConfig.requiresKernel)
        #expect(!runtimeConfig.requiresInitImage)
        #expect(runtimeConfig.requiresImageSnapshot)
    }

    private func loadRuntimeToml(_ runtimeSection: String) throws -> PluginConfig? {
        let tempURL = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: .temporaryDirectory,
            create: true
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let configURL = tempURL.appending(path: "config.toml")
        let configToml = """
            abstract = "Example runtime plugin"

            [servicesConfig]
            loadAtBoot = false
            runAtLoad = false
            defaultArguments = []

            [[servicesConfig.services]]
            type = "runtime"

            [runtimeConfig]
            \(runtimeSection)
            """
        try configToml.write(to: configURL, atomically: true, encoding: .utf8)
        return try PluginConfig(configURL: configURL)
    }

    @Test
    func testImagelessRuntimeConfigLoad() async throws {
        let config = try #require(
            try loadRuntimeToml(
                """
                requiresImage = false
                requiresKernel = false
                requiresInitImage = false
                requiresImageSnapshot = false
                platform = "darwin/arm64"
                """))
        let runtimeConfig = try #require(config.runtimeConfig)
        #expect(!runtimeConfig.requiresImage)
        #expect(!runtimeConfig.requiresKernel)
        #expect(!runtimeConfig.requiresInitImage)
        #expect(!runtimeConfig.requiresImageSnapshot)
        #expect(runtimeConfig.platform == "darwin/arm64")
        #expect(runtimeConfig.validate() == nil)
    }

    @Test
    func testInvalidRuntimeConfigTomlThrows() async throws {
        #expect(throws: (any Error).self) {
            try loadRuntimeToml("requiresImage = false\nrequiresKernel = false\nrequiresImageSnapshot = false")
        }
        #expect(throws: (any Error).self) {
            try loadRuntimeToml("platform = \"darwin\"")
        }
    }

    @Test
    func testRuntimeConfigValidate() {
        let imageless = { (kernel: Bool, snapshot: Bool, platform: String?) in
            PluginConfig.RuntimeConfig(
                requiresKernel: kernel, requiresInitImage: false, requiresImageSnapshot: snapshot, requiresImage: false, platform: platform)
        }
        #expect(PluginConfig.RuntimeConfig.default.validate() == nil)
        #expect(imageless(false, false, "darwin/arm64").validate() == nil)
        #expect(imageless(false, false, nil).validate() != nil)
        #expect(imageless(false, true, "darwin/arm64").validate() != nil)
        #expect(imageless(true, false, "darwin/arm64").validate() != nil)
        for bad in ["darwin", "darwin/", "a/b/c/d", "darwin /arm64", "", "/arm64", "darwin//arm64"] {
            #expect(PluginConfig.RuntimeConfig(platform: bad).validate() != nil, "platform \(bad)")
        }
        #expect(PluginConfig.RuntimeConfig(platform: "linux/arm64/v8").validate() == nil)
    }

    @Test
    func testRuntimePlatformParse() {
        let platform = PluginConfig.RuntimePlatform("darwin/arm64/v8")
        #expect(platform?.os == "darwin")
        #expect(platform?.architecture == "arm64")
        #expect(platform?.variant == "v8")
        #expect(PluginConfig.RuntimePlatform("darwin/arm64")?.variant == nil)
        #expect(PluginConfig.RuntimePlatform("darwin") == nil)
    }

    @Test
    func testMalformedTomlThrows() async throws {
        let tempURL = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: .temporaryDirectory,
            create: true
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let configURL = tempURL.appending(path: "config.toml")
        let malformedToml = """
            abstract = "unclosed string
            [invalid
            """
        try malformedToml.write(to: configURL, atomically: true, encoding: .utf8)
        #expect(throws: (any Error).self) {
            try PluginConfig(configURL: configURL)
        }
    }

    @Test
    func testUnsupportedExtensionReturnsNil() async throws {
        let tempURL = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: .temporaryDirectory,
            create: true
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let configURL = tempURL.appending(path: "config.yaml")
        let content = """
            abstract: "YAML config"
            author: "Apple"
            """
        try content.write(to: configURL, atomically: true, encoding: .utf8)
        let config = try PluginConfig(configURL: configURL)
        #expect(config == nil)
    }
}
