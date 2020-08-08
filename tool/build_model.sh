#!/bin/bash
set -e

WORKDIR="$(pwd)"

# get absolute paths
cd "$(dirname $0)/.."
PROJDIR="$(pwd)"
OUTDIR="$PROJDIR/webapp/lib"

cd ".."
LARKDIR="$(pwd)"

FIREBASEDIR="$LARKDIR/Katikati-PyLib/katikati_pylib/firebase"
CODEGEN="$LARKDIR/Infrastructure/tool/codegen"

cd "$CODEGEN"

# generate the file(s)
# add the following line to generate python export script
#   --export-script "$FIREBASEDIR/export_nook_model.g.py" \
dart bin/generate_firebase_model.dart \
    "$OUTDIR/model.yaml"

# assert that the generated file is valid Dart
dartanalyzer --packages "$PROJDIR/webapp/.packages" "$OUTDIR/model.g.dart"
