#!/usr/bin/env python3
"""Configure android build files for release on CI.

Fixes the recurring 'compileSdk 36 required' error from plugins like
file_picker / flutter_plugin_android_lifecycle by FORCING every gradle
module (including Flutter plugins, which live under the ROOT project) to
compileSdk=36 via a `subprojects` block in the ROOT build file.

Also:
  - sets compileSdk=36/targetSdk=36/minSdk=23 in the app module
  - injects a `release` signingConfig pointing at the decoded keystore
  - sets android.compileSdk in gradle.properties as a belt-and-suspenders

Supports both Groovy (build.gradle) and Kotlin (build.gradle.kts) DSLs.
"""
import os
import re

ROOT = os.environ.get("GITHUB_WORKSPACE", os.getcwd())
APP_DIR = os.path.join(ROOT, "android", "app")
ANDROID_DIR = os.path.join(ROOT, "android")


def dsl_of(path):
    return path.endswith(".kts")


def patch_app_module():
    """Set SDK versions + signing in android/app/build.gradle(.kts)."""
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


def force_root_subprojects():
    """Add a correct subprojects block to the ROOT android/build.gradle(.kts).
    If an old/invalid subprojects block is present, remove it first."""
    for fname in ("build.gradle.kts", "build.gradle"):
        PATH = os.path.join(ANDROID_DIR, fname)
        if not os.path.isfile(PATH):
            continue
        KTS = dsl_of(PATH)
        with open(PATH, "r", encoding="utf-8") as f:
            s = f.read()

        # Remove any pre-existing subprojects {...} block (invalid one from earlier runs)
        s = re.sub(r"\nsubprojects\s*\{.*?\n\}\n", "\n", s, flags=re.DOTALL)

        if KTS:
            block = (
                "\nsubprojects {\n"
                "    afterEvaluate {\n"
                "        if (project.hasProperty(\"android\")) {\n"
                "            project.android {\n"
                "                compileSdk = 36\n"
                "            }\n"
                "        }\n"
                "    }\n"
                "}\n"
            )
        else:
            block = (
                "\nsubprojects {\n"
                "    afterEvaluate { project ->\n"
                "        if (project.hasProperty('android')) {\n"
                "            project.android {\n"
                "                compileSdkVersion 36\n"
                "            }\n"
                "        }\n"
                "    }\n"
                "}\n"
            )
        s = s.rstrip() + "\n" + block
        with open(PATH, "w", encoding="utf-8") as f:
            f.write(s)
        print("root: forced subprojects compileSdk=36 (via %s)" % fname)
        return
    print("WARN: no root android/build.gradle(.kts) found")


def patch_gradle_properties():
    PROPS = os.path.join(ANDROID_DIR, "gradle.properties")
    if not os.path.isfile(PROPS):
        return
    with open(PROPS, "r", encoding="utf-8") as f:
        lines = f.readlines()
    want = {"android.compileSdk": "36", "android.targetSdk": "36", "android.minSdk": "23"}
    out = []
    for line in lines:
        key = line.split("=", 1)[0].strip()
        if key in want:
            out.append("%s=%s\n" % (key, want[key]))
            del want[key]
        else:
            out.append(line)
    for k, v in want.items():
        out.append("%s=%s\n" % (k, v))
    with open(PROPS, "w", encoding="utf-8") as f:
        f.writelines(out)
    print("gradle.properties: android.compileSdk=36, targetSdk=36, minSdk=23")


if __name__ == "__main__":
    patch_app_module()
    force_root_subprojects()
    patch_gradle_properties()
    print("DONE_CONFIG")
