#!/usr/bin/env python3
"""Write a complete, valid AndroidManifest.xml from android_manifest_REFERENCE.xml.

The old merge_manifest.py did fragile regex surgery on the flutter-generated
manifest and produced malformed XML (unbalanced <intent-filter> tags) which
broke :app:processReleaseMainManifest. Instead we take the REFERENCE file
(a full, valid manifest) as the source of truth and only fix up the
MainActivity package name to match the applicationId set by the package step.

The reference already contains: permissions, deep-link intent-filters,
audio_service <service>, MediaButtonReceiver, flutterEmbedding meta-data,
and url_launcher <queries>. It uses android:name=".MainActivity" (relative),
which Android resolves against the package/namespace — so no package rewrite
of the manifest itself is needed; the namespace in build.gradle handles it.
"""
import os
import sys
import xml.dom.minidom as minidom

ROOT = os.environ.get("GITHUB_WORKSPACE", os.getcwd())
REF = os.path.join(ROOT, "android_manifest_REFERENCE.xml")
MANIFEST = os.path.join(ROOT, "android", "app", "src", "main", "AndroidManifest.xml")


def main():
    if not os.path.isfile(REF):
        print("ERROR: reference manifest not found:", REF)
        sys.exit(1)
    os.makedirs(os.path.dirname(MANIFEST), exist_ok=True)

    with open(REF, "r", encoding="utf-8") as f:
        content = f.read()

    # Validate it parses as XML before writing (fail fast on CI).
    try:
        minidom.parseString(content)
    except Exception as e:
        print("ERROR: reference manifest is not valid XML:", e)
        sys.exit(1)

    with open(MANIFEST, "w", encoding="utf-8") as f:
        f.write(content)
    print("AndroidManifest.xml written from reference (valid XML)")


if __name__ == "__main__":
    main()
