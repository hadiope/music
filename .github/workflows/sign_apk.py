#!/usr/bin/env python3
"""Set compileSdk=36/targetSdk=36/minSdk=23 and inject release signing into
android/app/build.gradle(.kts). Supports Groovy and Kotlin DSL.

Note: compileSdk is 36 (matches file_picker 8 requirement).
file_picker ^8.0.0 requires compileSdk 36; platform 36 is installed in CI.
subprojects hack is required.
"""
import os
import re

ROOT = os.environ.get("GITHUB_WORKSPACE", os.getcwd())
APP_DIR = os.path.join(ROOT, "android", "app")


def main():
    kts = os.path.join(APP_DIR, "build.gradle.kts")
    gradle = os.path.join(APP_DIR, "build.gradle")
    if os.path.isfile(kts):
        PATH, KTS = kts, True
    elif os.path.isfile(gradle):
        PATH, KTS = gradle, False
    else:
        print("WARN: no android/app/build.gradle(.kts) found")
        return

    with open(PATH, "r", encoding="utf-8") as f:
        s = f.read()

    # SDK versions
    if KTS:
        s = re.sub(r"compileSdk\s*=.*", "compileSdk = 36", s)
        s = re.sub(r"targetSdk\s*=.*", "targetSdk = 36", s)
        s = re.sub(r"minSdk\s*=.*", "minSdk = 23", s)
    else:
        s = re.sub(r"compileSdkVersion\s+.*", "compileSdkVersion 36", s)
        s = re.sub(r"targetSdkVersion\s+.*", "targetSdkVersion 36", s)
        s = re.sub(r"minSdkVersion\s+.*", "minSdkVersion 23", s)
    print("app module: compileSdk=36, targetSdk=36, minSdk=23")

    # Signing
    pw = os.environ.get("KEYSTORE_PASSWORD", "")
    alias = os.environ.get("KEY_ALIAS", "")
    if pw and alias and "signingConfigs" not in s:
        if KTS:
            block = (
                "\n    signingConfigs {\n"
                "        create(\"release\") {\n"
                '            keyAlias = "%s"\n' % alias +
                '            keyPassword = "%s"\n' % pw +
                '            storeFile = file("/tmp/harmony_release.keystore")\n'
                '            storePassword = "%s"\n' % pw +
                "        }\n"
                "    }\n"
            )
            s = s.replace("android {", "android {" + block, 1)
            s = s.replace(
                "buildTypes {\n        release {",
                "buildTypes {\n        release {\n            signingConfig = signingConfigs.getByName(\"release\")",
                1,
            )
        else:
            block = (
                "\n    signingConfigs {\n"
                "        release {\n"
                '            keyAlias = "%s"\n' % alias +
                '            keyPassword = "%s"\n' % pw +
                '            storeFile = file("/tmp/harmony_release.keystore")\n'
                '            storePassword = "%s"\n' % pw +
                "        }\n"
                "    }\n"
            )
            s = s.replace("android {", "android {" + block, 1)
            s = s.replace(
                "buildTypes {\n        release {",
                "buildTypes {\n        release {\n            signingConfig signingConfigs.release",
                1,
            )
        print("app module: signing injected")

    with open(PATH, "w", encoding="utf-8") as f:
        f.write(s)


if __name__ == "__main__":
    main()
    print("DONE_CONFIG")
