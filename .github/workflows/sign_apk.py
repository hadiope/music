#!/usr/bin/env python3
"""Configure android build for release on CI.

1. app module: compileSdk=36, targetSdk=36, minSdk=24 + release signing
2. ROOT build.gradle(.kts): append a subprojects block that forces every
   plugin module (file_picker, lifecycle, ...) to compileSdk=36. This is
   required because those plugins are pre-compiled against android-34 and
   CheckAarMetadata fails otherwise.
   NOTE: flutter create regenerates android/build.gradle(.kts) fresh each run,
   so we just APPEND (no fragile regex removal needed).
3. gradle.properties: android.compileSdk=36 (belt-and-suspenders)

Supports both Groovy and Kotlin DSL. For the root file we always emit Kotlin
DSL syntax (modern Flutter generates .kts) using a safe cast via findByType.
"""
import os
import re

ROOT = os.environ.get("GITHUB_WORKSPACE", os.getcwd())
APP_DIR = os.path.join(ROOT, "android", "app")
ANDROID_DIR = os.path.join(ROOT, "android")


def patch_app_module():
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

    if KTS:
        s = re.sub(r"compileSdk\s*=.*", "compileSdk = 36", s)
        s = re.sub(r"targetSdk\s*=.*", "targetSdk = 36", s)
        s = re.sub(r"minSdk\s*=.*", "minSdk = 24", s)
    else:
        s = re.sub(r"compileSdkVersion\s+.*", "compileSdkVersion 36", s)
        s = re.sub(r"targetSdkVersion\s+.*", "targetSdkVersion 36", s)
        s = re.sub(r"minSdkVersion\s+.*", "minSdkVersion 24", s)
    print("app module: compileSdk=36, targetSdk=36, minSdk=24")

    pw = os.environ.get("KEYSTORE_PASSWORD", "")
    alias = os.environ.get("KEY_ALIAS", "")
    kspath = os.environ.get("KEYSTORE_PATH", "")
    if not kspath or not os.path.isfile(kspath):
        # fallback: look in android/app/keystore.jks (decoded from secret in CI)
        kspath = os.path.join(APP_DIR, "keystore.jks")
    if pw and alias and os.path.isfile(kspath) and "signingConfigs" not in s:
        if KTS:
            block = (
                "\n    signingConfigs {\n"
                "        create(\"release\") {\n"
                '            keyAlias = "%s"\n' % alias +
                '            keyPassword = "%s"\n' % pw +
                '            storeFile = file("%s")\n' % kspath +
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
    """Append a subprojects block to the ROOT android build file that forces
    every Android module (including Flutter plugins) to compileSdk=36."""
    kts = os.path.join(ANDROID_DIR, "build.gradle.kts")
    gradle = os.path.join(ANDROID_DIR, "build.gradle")
    if os.path.isfile(kts):
        PATH, KTS = kts, True
    elif os.path.isfile(gradle):
        PATH, KTS = gradle, False
    else:
        print("WARN: no root android/build.gradle(.kts) found")
        return

    with open(PATH, "r", encoding="utf-8") as f:
        s = f.read()

    # flutter create regenerates this file fresh each run, so normally no
    # stale subprojects block exists. But guard anyway by stripping any we
    # previously added (robust: remove from 'subprojects {' to the LAST '}').
    s = re.sub(r"\nsubprojects\s*\{.*\}\s*$", "\n", s, flags=re.DOTALL)

    if KTS:
        block = (
            "\nsubprojects {\n"
            "    afterEvaluate {\n"
            "        extensions.findByType(com.android.build.api.dsl.CommonExtension::class.java)?.let {\n"
            "            it.compileSdk = 36\n"
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
    print("root: forced subprojects compileSdk=36 (via %s)" % os.path.basename(PATH))


def patch_gradle_properties():
    PROPS = os.path.join(ANDROID_DIR, "gradle.properties")
    if not os.path.isfile(PROPS):
        return
    with open(PROPS, "r", encoding="utf-8") as f:
        lines = f.readlines()
    want = {"android.compileSdk": "36", "android.targetSdk": "36", "android.minSdk": "24"}
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
    print("gradle.properties: android.compileSdk=36, targetSdk=36, minSdk=24")


if __name__ == "__main__":
    patch_app_module()
    force_root_subprojects()
    patch_gradle_properties()
    print("DONE_CONFIG")
