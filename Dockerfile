# escape=`

# Builder image
FROM mcr.microsoft.com/windows/servercore:ltsc2019 as builder

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Download msvc components
ADD https://aka.ms/vs/16/release/vs_community.exe C:\
RUN C:\vs_community.exe --quiet --wait --norestart --noUpdateInstaller `
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        --add Microsoft.VisualStudio.Component.Windows10SDK.18362

# Build OpenSSL 1.1
FROM builder as openssl

# Install perl, required to build openssl
ADD https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.38.0.1-64bit.msi C:\
RUN Start-Process msiexec.exe -Wait -ArgumentList '/I C:\strawberry-perl-5.38.0.1-64bit.msi /quiet'

# Install NASM, optional for faster openssl function execution
ADD https://www.nasm.us/pub/nasm/releasebuilds/2.16.01/win64/nasm-2.16.01-win64.zip C:\
RUN Expand-Archive C:\nasm-2.16.01-win64.zip -DestinationPath C:\

# Set environment
RUN setx /M PATH $('C:\nasm-2.16.01;{0}' -f $env:PATH);

# Build and install openssl
ADD https://www.openssl.org/source/openssl-1.1.1w.tar.gz C:\
RUN tar -xzf C:\openssl-1.1.1w.tar.gz

SHELL ["cmd", "/S", "/C"]

# Build
RUN CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" `
      && CD openssl-1.1.1w `
      && perl Configure VC-WIN64A `
      && nmake

# Test
RUN CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" `
      && CD openssl-1.1.1w `
      && nmake test

# Install
RUN CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" `
      && CD openssl-1.1.1w `
      && nmake install


# Main image
FROM mcr.microsoft.com/windows/nanoserver:ltsc2019

COPY --from=openssl ["C:/Program Files/OpenSSL", "C:/Program Files/OpenSSL"]

