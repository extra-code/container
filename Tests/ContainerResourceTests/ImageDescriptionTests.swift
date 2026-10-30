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

import ContainerizationOCI
import Testing

@testable import ContainerResource

struct ImageDescriptionTests {
    @Test
    func noneFieldsMatchThePlaceholder() {
        let none = ImageDescription.none
        #expect(none.reference == "<none>")
        #expect(none.mediaType == "application/vnd.oci.image.index.v1+json")
        #expect(none.digest == "sha256:0000000000000000000000000000000000000000000000000000000000000000")
        #expect(none.descriptor.size == 0)
        #expect(none.isNone)
    }

    @Test(arguments: ["alpine:latest", "<none>:latest", "<NONE>", "", " <none>"])
    func isNoneKeysOnTheReferenceOnly(_ reference: String) {
        let description = ImageDescription(reference: reference, descriptor: ImageDescription.none.descriptor)
        #expect(!description.isNone)
    }

    @Test
    func isNoneIgnoresTheDigest() {
        let other = Descriptor(mediaType: "application/vnd.oci.image.index.v1+json", digest: "sha256:" + String(repeating: "1", count: 64), size: 1)
        #expect(ImageDescription(reference: "<none>", descriptor: other).isNone)
    }
}
