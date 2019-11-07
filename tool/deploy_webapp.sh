# Exit immediately if a command exits with a non-zero status
set -e
if [ $# -ne 1 ]; then
    echo "Usage: deploy.sh path/to/firebase/deployment/constants.json"
    exit 1
fi

FIREBASE_CONSTANTS="$1"
if [ ! -f "$FIREBASE_CONSTANTS" ]; then
  echo "could not find FIREBASE_CONSTANTS: $FIREBASE_CONSTANTS"
  echo "  in: `pwd`"
  exit 1
fi

# Remove previous build if it exists
rm -rf public

# Build
cd webapp
webdev build
mv build ../public
cd ..

# Copy the constants in the build folder
cp $FIREBASE_CONSTANTS public/assets/firebase_constants.json

# Get the project id
PROJECT_ID=$(cat $FIREBASE_CONSTANTS | python -c 'import json,sys; constants=json.load(sys.stdin); print(constants["projectId"])')

# Deploy
firebase deploy --project $PROJECT_ID --public public
