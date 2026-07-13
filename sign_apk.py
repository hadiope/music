#!/usr/bin/env python3
"""Inject a release signingConfig into the generated android/app/build.gradle.

Reads KEYSTORE_PASSWORD and KEY_ALIAS from the environment (GitHub Secret)
and writes the signingConfig pointing at the decoded keystore at
/tmp/harmony_release.keystore.
"""
import os

GRADLE = "android/app/build.gradle"


def main():
    pw = os.environ.get("KEYSTORE_PASSWORD", "")
    alias = os.environ.get("KEY_ALIAS", "")
    if not pw or not alias:
        print("KEYSTORE_PASSWORD or KEY_ALIAS not set; skipping signing injection")
        return

    if not os.path.exists(GRADLE):
        print("build.gradle not found, cannot inject signing")
        return

    with open(GRADLE, "r", encoding="utf-8") as f:
        s = f.read()

    if "signingConfigs" in s:
        print("signingConfigs already present")
        return

    signing_block = (
        "\n    signingConfigs {\n"
        "        release {\n"
        '            keyAlias = "%s"\n' % alias +
        '            keyPassword = "%s"\n' % pw +
        '            storeFile = file("/tmp/harmony_release.keystore")\n'
        '            storePassword = "%s"\n' % pw +
        "        }\n"
        "    }\n"
    )

    # Place signingConfigs right after the opening `android {`
    if "android {" in s:
        s = s.replace("android {", "android {" + signing_block, 1)
    else:
        print("android { block not found")
        return

    # Apply the signing config to the release build type
    original = "buildTypes {\n        release {"
    replacement = "buildTypes {\n        release {\n            signingConfig signingConfigs.release"
    if original in s:
        s = s.replace(original, replacement, 1)
    else:
        print("release buildTypes block not found; signing not applied")

    with open(GRADLE, "w", encoding="utf-8") as f:
        f.write(s)

    print("signing injected into build.gradle")


if __name__ == "__main__":
    main()
