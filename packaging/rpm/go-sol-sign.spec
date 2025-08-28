Name:           go-sol-sign
Version:        1.2.0
Release:        1%{?dist}
Summary:        Command-line tool for signing messages with Solana keypairs

License:        MIT
URL:            https://github.com/Aryamanraj/go-sol-sign
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  golang >= 1.21
BuildArch:      x86_64

%description
Sol-Sign is a lightweight command-line tool that allows users to
cryptographically sign messages using Ed25519 private keys in the
standard Solana keypair format.

This tool is useful for:
- Signing messages for authentication
- Creating proofs of ownership
- Integration with shell scripts
- Testing and development

%prep
%setup -q

%build
go build -ldflags="-w -s" -o %{name} .

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{_bindir}
mkdir -p $RPM_BUILD_ROOT%{_mandir}/man1
install -m 755 %{name} $RPM_BUILD_ROOT%{_bindir}/
install -m 644 packaging/rpm/%{name}.1 $RPM_BUILD_ROOT%{_mandir}/man1/

%files
%{_bindir}/%{name}
%{_mandir}/man1/%{name}.1*

%changelog
* Wed Aug 28 2025 Aryamanraj <your-email@example.com> - 1.0.0-1
- Initial release
- Command-line tool for signing messages with Solana keypairs
- Support for base64 and hex output formats
- Verbose mode and version information
