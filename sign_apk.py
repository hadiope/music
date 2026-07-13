#!/usr/bin/env python3
"""Configure android/app build file for release:
  - set compileSdk=36, targetSdk=36, minSdk=23 (required by file_picker etc.)
  - inject a `release` signingConfig that points at the decoded keystore.
  - force ALL subprojects (plugins) to compileSdk=36 via subprojects block.

Supports both Groovy (build.gradle) and Kotlin (build.gradle.kts) DSLs.
"""
import os
import re

ROOT = os.environ.get("GITHUB_WORKSPACE", os.getcwd())
APP_DIR = os.path.join(ROOT, "android", "app")

KTS = os.path.join(APP_DIR, "build.gradle.kts")
GRADLE = os.path.join(APP_DIR, "build.gradle")

if os.path.isfile(KTS):
    PATH = KTS
    KTS_DSL = True
elif os.path.isfile(GRADLE):
    PATH = GRADLE
    KTS_DSL = False
else:
    print("ERROR: no android/app/build.gradle(.kts) found")
    raise SystemExit(1)

with open(PATH, "r", encoding="utf-8") as f:
    s = f.read()

# --- 1. SDK versions ---
if KTS_DSL:
    s = re.sub(r"compileSdk\s*=.*", "compileSdk = 36", s)
    s = re.sub(r"targetSdk\s*=.*", "targetSdk = 36", s)
    s = re.sub(r"minSdk\s*=.*", "minSdk = 23", s)
else:
    s = re.sub(r"compileSdkVersion\s+.*", "compileSdkVersion 36", s)
    s = re.sub(r"targetSdkVersion\s+.*", "targetSdkVersion 36", s)
    s = re.sub(r"minSdkVersion\s+.*", "minSdkVersion 23", s)

print("SDK set: compileSdk=36, targetSdk=36, minSdk=23")

# --- 2. Signing config ---
pw = os.environ.get("KEYSTORE_PASSWORD", "")
alias = os.environ.get("KEY_ALIAS", "")
if not pw or not alias:
    print("KEYSTORE_PASSWORD/KEY_ALIAS missing; skipping signing injection")
else:
    if "signingConfigs" in s:
        print("signingConfigs already present")
    else:
        if KTS_DSL:
            signing_block = (
                "\n    signingConfigs {\n"
                "        create(\"release\") {\n"
                '            keyAlias = "%s"\n' % alias +
                '            keyPassword = "%s"\n' % pw +
                '            storeFile = file("/tmp/harmony_release.keystore")\n'
                '            storePassword = "%s"\n' % pw +
                "        }\n"
                "    }\n"
            )
            s = s.replace("android {", "android {" + signing_block, 1)
            s = s.replace(
                "buildTypes {\n        release {",
                "buildTypes {\n        release {\n            signingConfig = signingConfigs.getByName(\"release\")",
                1,
            )
        else:
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
            s = s.replace("android {", "android {" + signing_block, 1)
            s = s.replace(
                "buildTypes {\n        release {",
                "buildTypes {\n        release {\n            signingConfig signingConfigs.release",
                1,
            )
        print("signing injected")

# --- 3. Force ALL subprojects (plugins like file_picker) to compileSdk 36 ---
if KTS_DSL:
    force_block = (
        "\n"
        "subprojects {\n"
        "    afterEvaluate {\n"
        "        extensions.findByType<com.android.build.api.dsl.CommonExtension>()?.let {\n"
        "            it.compileSdk = 36\n"
        "            it.defaultConfig.minSdk = 23\n"
        "        }\n"
        "    }\n"
        "}\n"
    )
else:
    force_block = (
        "\n"
        "allprojects {\n"
        "    afterEvaluate { project ->\n"
        "        if (project.hasProperty('android')) {\n"
        "            project.android {\n"
        "                compileSdkVersion 36\n"
        "                defaultConfig { minSdkVersion 23 }\n"
        "            }\n"
        "        }\n"
        "    }\n"
        "}\n"
    )

if "subprojects {" not in s and "allprojects {" not in s:
    s += force_block
    print("forced subprojects compileSdk=36")
else:
    print("subprojects/allprojects block already present")

with open(PATH, "w", encoding="utf-8") as f:
    f.write(s)

# echo the relevant lines for debug
for line in s.splitlines():
    if re.search(r"compileSdk|targetSdk|minSdk|signingConfig|signingConfigs", line):
        print("  ->", line.strip())
