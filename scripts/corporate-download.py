#!/usr/bin/env python3
"""Validate and fetch reviewed artifacts without public registry fallback."""
import base64
import hashlib
import os
from pathlib import Path
import ssl
import sys
import tarfile
import tempfile
import urllib.parse
import urllib.request
import zipfile


class AcquisitionError(ValueError):
    pass


def origin(url):
    parsed = urllib.parse.urlsplit(url)
    if (parsed.scheme != "https" or not parsed.hostname or parsed.username or
            parsed.password or parsed.fragment):
        raise AcquisitionError("Require an HTTPS URL without credentials or fragments")
    return parsed.hostname.lower(), parsed.port or 443


def internal_registry(variable):
    url = os.environ.get(variable, "")
    host, _ = origin(url)
    if host in {"registry.invalid", "registry.npmjs.org", "pypi.org", "files.pythonhosted.org"}:
        raise AcquisitionError(f"Configure {variable} with the authorized internal registry (AGENTS.md C06)")
    return url


def authorized_url(url, registry=None):
    host, port = origin(url)
    if registry:
        return (host, port) == origin(registry)
    parsed = urllib.parse.urlsplit(url)
    return host == "github.com" and port == 443 and "/releases/download/" in parsed.path


class ApprovedRedirects(urllib.request.HTTPRedirectHandler):
    def __init__(self, registry):
        self.registry = registry

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        host, port = origin(newurl)
        allowed = ((host, port) == origin(self.registry) if self.registry else
                   port == 443 and host in {"github.com", "release-assets.githubusercontent.com",
                                            "objects.githubusercontent.com"})
        if not allowed:
            raise AcquisitionError("Download redirect leaves the approved source; resolve C03/C06")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def fetch(url, destination, checksum, algorithm="sha256", registry=None):
    """Only explicit sources; no installer execution. Never display auth/URLs."""
    if not authorized_url(url, registry):
        raise AcquisitionError("Artifact URL is outside the reviewed GitHub/internal source")
    if algorithm not in {"sha256", "sha512"}:
        raise AcquisitionError("Only SHA256/SHA512 integrity is supported")
    expected_length = 64 if algorithm == "sha256" else 128
    if len(checksum) != expected_length or any(c not in "0123456789abcdef" for c in checksum):
        raise AcquisitionError("Missing or invalid artifact digest")
    destination = Path(destination)
    if destination.is_file() and hashlib.new(algorithm, destination.read_bytes()).hexdigest() == checksum:
        return destination
    destination.parent.mkdir(parents=True, exist_ok=True)
    descriptor, name = tempfile.mkstemp(prefix=destination.name + ".partial-", dir=destination.parent)
    os.close(descriptor)
    partial = Path(name)
    request = urllib.request.Request(url, headers={"User-Agent": "dotfiles-corporate"})
    if registry:
        token = os.environ.get("DOTFILES_ARTIFACTORY_TOKEN")
        username = os.environ.get("DOTFILES_ARTIFACTORY_USERNAME")
        password = os.environ.get("DOTFILES_ARTIFACTORY_PASSWORD")
        if username and password:
            value = base64.b64encode(f"{username}:{password}".encode()).decode()
            request.add_header("Authorization", "Basic " + value)
        elif token:
            request.add_header("Authorization", "Bearer " + token)
    context = ssl.create_default_context()
    opener = urllib.request.build_opener(ApprovedRedirects(registry), urllib.request.HTTPSHandler(context=context))
    digest = hashlib.new(algorithm)
    try:
        with opener.open(request, timeout=30) as response, partial.open("wb") as output:
            while chunk := response.read(1024 * 1024):
                digest.update(chunk)
                output.write(chunk)
        if digest.hexdigest() != checksum:
            raise AcquisitionError("Artifact checksum mismatch; previous installation preserved")
        partial.replace(destination)
    finally:
        partial.unlink(missing_ok=True)
    return destination


def extract(archive, destination):
    """Extract verified archives into a staging directory, rejecting escapes."""
    if zipfile.is_zipfile(archive):
        with zipfile.ZipFile(archive) as zipped:
            for name in zipped.namelist():
                path = Path(name)
                if path.is_absolute() or ".." in path.parts:
                    raise AcquisitionError("Unsafe ZIP member")
            zipped.extractall(destination)
    else:
        with tarfile.open(archive) as tar:
            tar.extractall(destination, filter="data")


if __name__ == "__main__":
    try:
        if sys.argv[1] == "extract" and len(sys.argv) == 4:
            extract(sys.argv[2], sys.argv[3])
        elif sys.argv[1] == "fetch" and len(sys.argv) == 5:
            fetch(sys.argv[2], sys.argv[3], sys.argv[4])
        else:
            raise AcquisitionError("Usage: corporate-download.py fetch URL DEST SHA256 | extract ARCHIVE DEST")
    except (ValueError, OSError, IndexError, tarfile.TarError, zipfile.BadZipFile):
        print("Corporate artifact download/extraction failed; check source, checksum, TLS and archive safety (C03/C04/C13)", file=sys.stderr)
        raise SystemExit(1)
