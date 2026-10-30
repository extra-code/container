---
# SPDX-FileCopyrightText: 2026 Christian Semmelmann
# SPDX-License-Identifier: Apache-2.0
title: container (patched for Parbake)
description: Temporary patched build of Apple container that runs the Parbake macOS runtime.
keywords: container,macos,virtualization,apple-silicon,parbake
---

# container, patched for Parbake

This package is a temporary patched build of [apple/container](https://github.com/apple/container), built from the fork [extra-code/container](https://github.com/extra-code/container). It is not made or endorsed by Apple.

The patches let the [Parbake](https://ocx.sh/catalog/extra-code/parbake) runtime plugin run macOS guests. The package goes away once Apple ships the patches in a release.

Tags follow the upstream version plus a two-digit build counter: `1.6.1_01` is the first build on top of apple/container 1.6.1.

## Install

Install it together with Parbake, as the [Parbake quickstart](https://github.com/extra-code/parbake/blob/main/docs/quickstart.md) describes:

```bash
ocx package install --link ~/.parbake/container ghcr.io/extra-code/container:1.6.1_01
```

The install line uses the registry name, because the signature trust policy matches it.

It does not replace a stock `container` install, and only one set of `container` services runs at a time.
