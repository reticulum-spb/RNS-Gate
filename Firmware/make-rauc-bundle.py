#!/usr/bin/env python3
"""Build a signed plain RAUC bundle from a Buildroot rootfs image."""

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BOARD_DIR = SCRIPT_DIR / "system" / "br2_external" / "board" / "gate"
KEYS_DIR = SCRIPT_DIR / "rauc-keys"
OUT_DIR = SCRIPT_DIR / "docker" / "output"
CERT = KEYS_DIR / "cert.pem"
KEY = KEYS_DIR / "key.pem"
MANIFEST = BOARD_DIR / "manifest.raucm"


def run(command: list[str]) -> None:
    """Run a command while keeping its output and errors visible to the user."""
    print("+", " ".join(command))
    subprocess.run(command, check=True)


def require_tools() -> None:
    missing = [tool for tool in ("mksquashfs", "openssl") if shutil.which(tool) is None]
    if missing:
        names = ", ".join(missing)
        raise RuntimeError(
            f"required command not found: {names}. "
            "Install squashfs-tools and OpenSSL (for example: brew install squashfs-tools openssl)."
        )


def ensure_signing_keypair() -> None:
    cert_exists = CERT.is_file()
    key_exists = KEY.is_file()
    if cert_exists and key_exists:
        return
    if cert_exists or key_exists:
        missing = KEY if cert_exists else CERT
        raise RuntimeError(
            f"incomplete signing keypair: {missing} is missing; refusing to overwrite the existing key"
        )

    print(f">> Generating dev signing keypair in {KEYS_DIR} (one-time)")
    KEYS_DIR.mkdir(parents=True, exist_ok=True)
    run(
        [
            "openssl",
            "req",
            "-x509",
            "-newkey",
            "rsa:4096",
            "-nodes",
            "-days",
            "3650",
            "-subj",
            "/CN=RNS Gate Dev CA",
            "-addext",
            "basicConstraints=critical,CA:TRUE",
            "-keyout",
            str(KEY),
            "-out",
            str(CERT),
        ]
    )


def sha256_and_size(path: Path) -> tuple[str, int]:
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
            size += len(chunk)
    return digest.hexdigest(), size


def prepare_manifest(rootfs: Path, destination: Path) -> str:
    text = MANIFEST.read_text(encoding="utf-8")
    version_match = re.search(r"(?m)^version=(.+)$", text)
    if version_match is None:
        raise RuntimeError(f"version=... not found in {MANIFEST}")
    version = version_match.group(1).strip()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._+-]*", version):
        raise RuntimeError(f"unsafe version for output filename: {version!r}")

    # Plain bundles include the image checksum and size in the internal manifest.
    text, format_replacements = re.subn(r"(?m)^format=.*$", "format=plain", text, count=1)
    if format_replacements != 1:
        raise RuntimeError(f"format=... not found in {MANIFEST}")
    checksum, size = sha256_and_size(rootfs)
    image_match = re.search(r"(?m)^filename=rootfs\.ext4\s*$", text)
    if image_match is None:
        raise RuntimeError("filename=rootfs.ext4 not found in the RAUC manifest")
    details = f"filename=rootfs.ext4\nsha256={checksum}\nsize={size}"
    text = text[: image_match.start()] + details + text[image_match.end() :]
    destination.write_text(text, encoding="utf-8")
    return version


def build_bundle(rootfs: Path) -> Path:
    require_tools()
    ensure_signing_keypair()
    if not rootfs.is_file():
        raise FileNotFoundError(f"rootfs not found: {rootfs}")
    if not MANIFEST.is_file():
        raise FileNotFoundError(f"manifest not found: {MANIFEST}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".rns-gate-bundle-", dir=OUT_DIR) as temporary_dir:
        temporary_root = Path(temporary_dir)
        stage = temporary_root / "stage"
        stage.mkdir()
        version = prepare_manifest(rootfs, stage / "manifest.raucm")
        shutil.copy2(rootfs, stage / "rootfs.ext4")
        output = OUT_DIR / f"update-{version}.raucb"
        # Keep intermediates in a hidden directory on the output filesystem so
        # replacement stays atomic and an existing bundle remains untouched.
        squashfs = temporary_root / "payload.squashfs"
        signature = temporary_root / "payload.sig"
        temporary_output = temporary_root / "bundle.raucb"

        run(
            [
                "mksquashfs",
                str(stage),
                str(squashfs),
                "-quiet",
                "-noappend",
                "-comp",
                "gzip",
                "-all-root",
            ]
        )
        run(
            [
                "openssl",
                "cms",
                "-sign",
                "-binary",
                "-outform",
                "DER",
                "-md",
                "sha256",
                "-signer",
                str(CERT),
                "-inkey",
                str(KEY),
                "-in",
                str(squashfs),
                "-out",
                str(signature),
            ]
        )

        # RAUC plain format: squashfs payload, detached CMS, BE uint64 sig size.
        with temporary_output.open("wb") as bundle, squashfs.open("rb") as payload, signature.open("rb") as sig:
            shutil.copyfileobj(payload, bundle)
            shutil.copyfileobj(sig, bundle)
            bundle.write(struct.pack(">Q", signature.stat().st_size))

        # Replace only after the complete bundle has been written successfully.
        temporary_output.replace(output)

    print(f"{output.stat().st_size:>12} {output}")
    print(f">> Bundle ready (signed plain, dev CA): {output}")
    print(">> Deploy:       scp {0} root@<gate>:/mnt/rns/ && rauc install /mnt/rns/{1}".format(output, output.name))
    return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("rootfs", nargs="?", type=Path, help="rootfs.ext4 path")
    args = parser.parse_args()
    rootfs = args.rootfs or (OUT_DIR / "rootfs.ext4")
    try:
        build_bundle(rootfs.expanduser().resolve())
    except (FileNotFoundError, OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
