#!/usr/bin/env bash
# Should be part of the flake, but apperlm's build system requires Internet

JSON_VERSION="4.10"
CURSES_UI_VERSION="0.9609"
APPERL_VERSION="0.6.1"

URLS=(
    "https://cpan.metacpan.org/authors/id/I/IS/ISHIGAKI/JSON-$JSON_VERSION.tar.gz"
    "https://cpan.metacpan.org/authors/id/M/MD/MDXI/Curses-UI-$CURSES_UI_VERSION.tar.gz"
    "https://github.com/G4Vi/Perl-Dist-APPerl/releases/download/v$APPERL_VERSION/perl.com"
)

mkdir -p modules

for url in "${URLS[@]}"; do
    filename="${url##*/}"
    if [ ! -f "modules/$filename" ]; then
        wget -O "modules/$filename" "$url"
    fi
done

chmod +x modules/perl.com

rm distrousurp

./modules/perl.com -Ilib apperlm checkout DistroUsurp
./modules/perl.com -Ilib apperlm configure
./modules/perl.com -Ilib apperlm build

# Using APPerl as more of a packer than a cross-OS tool. I want it to work on old distros, but not Windows really

./distrousurp --assimilate
rm distrousurp.dbg