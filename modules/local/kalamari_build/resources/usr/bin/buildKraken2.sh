#!/bin/bash

set -eu

KALAMARI_VER=$(downloadKalamari.pl --version)

sharedir=share/kalamari-$KALAMARI_VER
SRC="$sharedir/kalamari-kraken2"
TAXDIR="$sharedir/taxonomy/filtered"

# Test prereqs
which kraken2-build
which jellyfish

export tmpfile=$(mktemp --suffix=.fasta)
trap 'rm -f $tmpfile' EXIT

export DB="$sharedir/kalamari-kraken2"
mkdir -pv $DB/library
cp -rv $TAXDIR $DB/taxonomy

# Make --add-to-library more efficient with
# concatenated fasta files
# find $SRC -name '*.fasta.gz' | \ # arzoo changed 20260902
find kalamari-$KALAMARI_VER/kalamari/ -name '*.fasta.gz' | \
  xargs -n 100 -P 1 bash -c '
    for i in "$@"; do
      gzip -cd $i
    done > $tmpfile
    echo $DB
    kraken2-build --db $DB --add-to-library $tmpfile
  '

# Build the database
kraken2-build --db $DB --build --threads 1
# Reduce the size of the database
kraken2-build --db $DB --clean

