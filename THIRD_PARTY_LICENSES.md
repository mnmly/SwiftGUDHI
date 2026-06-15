# Third-party licenses — SwiftGUDHIFull (GPL-3.0)

This package links `GudhiCoreFull.xcframework`, which statically links the
libraries below. Because CGAL's triangulation packages are GPL-3.0-or-later, the
**binary — and any app linking this package — is GPL-3.0-or-later.**

| Component | License (SPDX) | Notes |
|---|---|---|
| SwiftGUDHIFull (this package) | MIT | original Swift source |
| GUDHI 3.12.0 | MIT | TDA algorithms |
| Boost | BSL-1.0 | header-only |
| Hera | BSD | bottleneck / Wasserstein |
| CGAL kernels (Epeck_d/Epick_d) | LGPL-3.0-or-later | |
| **CGAL dD Triangulation** | **GPL-3.0-or-later** | Alpha / Tangential / Euclidean Witness ⇒ GPL binary |
| Eigen | MPL-2.0 | via CGAL |
| GMP / MPFR | LGPL-3.0+ | static-linked |

Effective license of the binary: **GPL-3.0-or-later** (see LICENSE.GPL-3.0).
For a permissive build, use the `SwiftGUDHI` package (main branch).
