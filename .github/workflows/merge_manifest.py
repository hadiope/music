#!/usr/bin/env python3
"""Merge required manifest entries from android_manifest_REFERENCE.xml into the
generated android/app/src/main/AndroidManifest.xml.

Adds (idempotently):
  - uses-permission lines (INTERNET, FOREGROUND_SERVICE, etc.)
  - the just_audio / audio_service <service> block
  - deep-link <intent-filter> blocks (https thetextstory.com/playlist + iranseda scheme)
"""
import os
import re

ROOT = os.environ.get("GITHUB_WORKSPACE", os.getcwd())
REF = os.path.join(ROOT, "android_manifest_REFERENCE.xml")
MANIFEST = os.path.join(ROOT, "android", "app", "src", "main", "AndroidManifest.xml")


def _insert_into_activity(m, block):
    """Insert a deep-link <intent-filter> inside the launcher <activity>."""
    # Find the launcher activity block (the one with MAIN/LAUNCHER filter)
    act_start = m.find('<activity')
    if act_start == -1:
        return m, False
    act_end = m.find('</activity>', act_start)
    if act_end == -1:
        return m, False
    activity = m[act_start:act_end]
    if block.strip() in activity:
        return m, False  # already present
    # insert before the closing </activity>
    new_activity = activity[:-len('</activity>')] + "            " + block.strip() + "\n        </activity>"
    m = m[:act_start] + new_activity + m[act_end + len('</activity>'):]
    return m, True


def main():
    if not os.path.isfile(REF):
        print("WARN: reference manifest not found, skipping")
        return
    if not os.path.isfile(MANIFEST):
        print("WARN: app manifest not found, skipping")
        return

    with open(REF, "r", encoding="utf-8") as f:
        ref = f.read()
    with open(MANIFEST, "r", encoding="utf-8") as f:
        m = f.read()

    changed = False

    # 1) permissions
    perms = re.findall(
        r'<uses-permission\s+android:name="[^"]+"\s*/>', ref)
    for p in perms:
        if p not in m:
            if "<manifest" in m:
                m = re.sub(r"(<manifest[^>]*>)",
                           lambda mo: mo.group(1) + "\n    " + p, m, count=1)
            changed = True
            print("added permission:", p)

    # 2) audio_service <service> block
    svc = re.search(r"<service[^>]*com\.ryanheise\.audioservice[^>]*>.*?</service>",
                    ref, re.DOTALL)
    if svc and svc.group(0) not in m:
        block = svc.group(0)
        if "</application>" in m:
            m = m.replace("</application>",
                          "        " + block.strip() + "\n    </application>", 1)
            changed = True
            print("added audio_service <service>")
        else:
            print("WARN: no </application> found")

    # 3) deep-link <intent-filter> blocks (https + custom scheme)
    deep_links = re.findall(
        r'<intent-filter>\s*<action android:name="android\.intent\.action\.VIEW"/>.*?</intent-filter>',
        ref, re.DOTALL)
    for dl in deep_links:
        if dl.strip() not in m:
            m, inserted = _insert_into_activity(m, dl)
            if inserted:
                changed = True
                print("added deep-link intent-filter")
            else:
                print("WARN: could not insert deep-link (activity not found)")

    if changed:
        with open(MANIFEST, "w", encoding="utf-8") as f:
            f.write(m)
        print("manifest merged")
    else:
        print("manifest already up to date")


if __name__ == "__main__":
    main()
