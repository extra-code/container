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

import ContainerizationError
import ContainerizationOCI

/// A type that represents an OCI image that can be used with sandboxes or containers.
public struct ImageDescription: Sendable, Codable {
    /// The public reference/name of the image.
    public let reference: String
    /// The descriptor of the image.
    public let descriptor: Descriptor

    public var digest: String { descriptor.digest }
    public var mediaType: String { descriptor.mediaType }

    public init(reference: String, descriptor: Descriptor) {
        self.reference = reference
        self.descriptor = descriptor
    }

    /// The placeholder image of a container whose runtime needs no image.
    /// Its descriptor is well formed but matches no stored image.
    public static let none = ImageDescription(
        reference: noneReference,
        descriptor: Descriptor(
            mediaType: "application/vnd.oci.image.index.v1+json",
            digest: "sha256:" + String(repeating: "0", count: 64),
            size: 0
        )
    )

    private static let noneReference = "<none>"

    /// Whether this is the placeholder image. Keys on the reference, never on the digest.
    public var isNone: Bool { reference == Self.noneReference }
}
