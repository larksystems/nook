# Exit immediately if a command exits with a non-zero status
set -e
if [ $# -ne 2 ]; then
    echo "Usage: $0 path/to/firebase/deployment/constants.json path/to/crypto/token/file"
    exit 1
fi

########## cd to the nook project directory and get the absolute path

cd "$(dirname "$0")"/..
PROJDIR="$(pwd)"

########## validate argument(s)

FIREBASE_CONSTANTS="$1"
if [ ! -f "$FIREBASE_CONSTANTS" ]; then
  echo "could not find FIREBASE_CONSTANTS: $FIREBASE_CONSTANTS"
  echo "  in: $(pwd)"
  exit 1
fi

CRYPTO_TOKEN_FILE="$2"
if [ ! -f "$CRYPTO_TOKEN_FILE" ]; then
  echo "could not find CRYPTO_TOKEN_FILE: $CRYPTO_TOKEN_FILE"
  echo "  in: $(pwd)"
  exit 1
fi

########## ensure that node modules have been installed

echo "node version $(node --version)"
if [ ! -d "$PROJDIR/functions/node_modules" ]; then
  echo "before deploying, run 'npm install' in $PROJDIR/functions"
  exit 1
fi

########## rebuild the webapp

# Remove previous build if it exists
rm -rf public

# Build
cd webapp
echo "building webapp ..."
webdev build
echo "build complete"
mv build ../public
cd ..

# Copy the constants in the build folder
cp $FIREBASE_CONSTANTS public/assets/firebase_constants.json

# Copy the latest commit sha1 hash on origin/master into the build folder
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
LASTEST_COMMIT_HASH=$(git rev-parse $CURRENT_BRANCH)
DEPLOY_DATA="\"latestCommitHash\": \"$LASTEST_COMMIT_HASH\""
DEPLOY_DATA="$DEPLOY_DATA, \"timestamp\": \"$(date +"%Y-%m-%dT%H:%M:%S")\""
DEPLOY_DATA="$DEPLOY_DATA, \"deployed_by\": \"$(git config --get user.email)\""
echo "{$DEPLOY_DATA}" > public/assets/latest_commit_hash.json

# Prepare file with content to be uploaded to firebase
DEPLOY_DATA="$DEPLOY_DATA, \"__reference_path\": \"metadata/nook_app\""
DEPLOY_DATA="$DEPLOY_DATA, \"__id\": \"nook_app\""
DEPLOY_DATA="$DEPLOY_DATA, \"__subcollections\": [ ]"
echo "{\"metadata\": [ {$DEPLOY_DATA} ] }" > public_metadata_nook_app.json

########## deploy webapp

# Get the project id
echo "getting project id..."
PROJECT_ID=$(cat $FIREBASE_CONSTANTS | python -c 'import json,sys; constants=json.load(sys.stdin); print(constants["projectId"])')
echo "project id: $PROJECT_ID"

# Deploy using the local firebase instance
echo "deploying to firebase..."
node $PROJDIR/functions/node_modules/.bin/firebase \
  deploy \
  --project $PROJECT_ID \
  --public public
echo "firebase deploy result: $?"

echo "updating nook webapp metadata..."
cd tool
pipenv run python json_to_firebase.py "$CRYPTO_TOKEN_FILE" ../public_metadata_nook_app.json
cd ..

echo "deployment complete"
