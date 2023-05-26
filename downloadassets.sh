#!/bin/sh
FULLURL="https://github.com/STJr/SRB2/releases/download/SRB2_release_2.2.10/SRB2-v2210-Full.zip"
PATCHURL=""
DOWNLOADCMD="curl -Lo"

cd assets
rm *.srb *.pk3 *.dta *.wad
${DOWNLOADCMD} srb2full.zip ${FULLURL}
unzip -o -j srb2full.zip "*.srb" "*.pk3" "*.dta" "*.wad" "*.dat"
rm srb2full.zip

cd patch
rm *.srb *.pk3 *.dta *.wad
if [ ! -z "$PATCHURL" ];
then
    ${DOWNLOADCMD} srb2patch.zip ${PATCHURL}
    unzip -o -j srb2patch.zip "*.srb" "*.pk3" "*.dta" "*.wad" "*.dat"
    rm srb2patch.zip
    cp * ..
fi
cd ../.. 