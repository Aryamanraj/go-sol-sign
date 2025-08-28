#!/bin/bash

# Script to build Debian package for sol-sign

set -e

VERSION="1.0.0"
ARCH="amd64"
PACKAGE_NAME="sol-sign"
MAINTAINER="Aryamanraj <your-email@example.com>"
DESCRIPTION="Command-line tool for signing messages with Solana keypairs"

# Create package directory structure
PACKAGE_DIR="packaging/deb/${PACKAGE_NAME}_${VERSION}_${ARCH}"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"/{DEBIAN,usr/bin,usr/share/doc/${PACKAGE_NAME},usr/share/man/man1}

# Build the binary
echo "Building binary..."
go build -ldflags="-w -s" -o "$PACKAGE_DIR/usr/bin/sol-sign" .

# Create DEBIAN/control file
cat > "$PACKAGE_DIR/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: $MAINTAINER
Description: $DESCRIPTION
 Sol-Sign is a lightweight command-line tool that allows users to
 cryptographically sign messages using Ed25519 private keys in the
 standard Solana keypair format.
 .
 This tool is useful for:
 - Signing messages for authentication
 - Creating proofs of ownership
 - Integration with shell scripts
 - Testing and development
Homepage: https://github.com/Aryamanraj/go-sol-sign
EOF

# Create copyright file
cat > "$PACKAGE_DIR/usr/share/doc/${PACKAGE_NAME}/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: sol-sign
Upstream-Contact: Aryamanraj <your-email@example.com>
Source: https://github.com/Aryamanraj/go-sol-sign

Files: *
Copyright: 2025 Aryamanraj
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
EOF

# Create man page
cat > "$PACKAGE_DIR/usr/share/man/man1/sol-sign.1" << EOF
.TH SOL-SIGN 1 "$(date +%Y-%m-%d)" "sol-sign $VERSION" "User Commands"
.SH NAME
sol-sign \- sign messages with Solana keypairs
.SH SYNOPSIS
.B sol-sign
\-keypair \fIPATH\fR \-message \fIMESSAGE\fR [\-format \fIFORMAT\fR] [\-verbose] [\-version]
.SH DESCRIPTION
.B sol-sign
is a command-line tool for cryptographically signing messages using Ed25519
private keys in the standard Solana keypair format.
.SH OPTIONS
.TP
\fB\-keypair\fR \fIPATH\fR
Path to Solana keypair JSON file (required)
.TP
\fB\-message\fR \fIMESSAGE\fR
Message to sign (required)
.TP
\fB\-format\fR \fIFORMAT\fR
Output format: base64 or hex (default: base64)
.TP
\fB\-verbose\fR
Enable verbose output
.TP
\fB\-version\fR
Show version information
.SH EXAMPLES
Sign a message with base64 output:
.PP
.nf
.RS
sol-sign -keypair ~/.config/solana/id.json -message "Hello World"
.RE
.fi
.PP
Sign a message with hex output:
.PP
.nf
.RS
sol-sign -keypair ./keypair.json -message "Test" -format hex
.RE
.fi
.SH EXIT STATUS
.TP
0
Success
.TP
1
Error occurred
.SH AUTHOR
Aryamanraj <your-email@example.com>
.SH SEE ALSO
.BR solana-keygen (1)
EOF

# Compress man page
gzip -9 "$PACKAGE_DIR/usr/share/man/man1/sol-sign.1"

# Create changelog
cat > "$PACKAGE_DIR/usr/share/doc/${PACKAGE_NAME}/changelog.Debian" << EOF
sol-sign ($VERSION) unstable; urgency=low

  * Initial release.
  * Command-line tool for signing messages with Solana keypairs.
  * Support for base64 and hex output formats.
  * Verbose mode and version information.

 -- $MAINTAINER  $(date -R)
EOF

# Compress changelog
gzip -9 "$PACKAGE_DIR/usr/share/doc/${PACKAGE_NAME}/changelog.Debian"

# Set permissions
chmod 755 "$PACKAGE_DIR/usr/bin/sol-sign"
find "$PACKAGE_DIR" -type f -exec chmod 644 {} \;
chmod 755 "$PACKAGE_DIR/usr/bin/sol-sign"

# Build the package
echo "Building Debian package..."
dpkg-deb --build "$PACKAGE_DIR"

echo "✅ Debian package created: ${PACKAGE_DIR}.deb"
echo ""
echo "To install:"
echo "  sudo dpkg -i ${PACKAGE_DIR}.deb"
echo ""
echo "To upload to a repository, you'll need to sign it:"
echo "  debsign ${PACKAGE_DIR}.deb"
