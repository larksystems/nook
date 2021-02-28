# Exit immediately if a command exits with a non-zero status
set -e

WORK_DIR="$(pwd)"

########## parse and validate argument(s)

usage_and_exit() {
  echo "Usage: $0 [--skip-cloud-functions] [--only hosting|database|firestore] path/to/firebase/deployment/constants.json path/to/crypto/token/file"
  exit 1
}

just_exit() {
  exit 1
}

FIREBASE_DEPLOY_ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-cloud-functions)
      SKIP_CLOUD_FUNCTIONS=true
      shift
      ;;
    --only)
      shift
      FIREBASE_DEPLOY_ARGS[0]="--only"
      if [ -z "$1" ]; then
        echo "expected a specific firebase service to deploy"
        usage_and_exit
      fi
      FIREBASE_DEPLOY_ARGS[1]="$1"
      shift
      ;;
    *)
      # Don't process any other arguments after the optional ones
      break
      ;;
  esac
done

if [ $# -ne 2 ]; then
  echo "expected 2 required arguments"
  usage_and_exit
fi

FIREBASE_CONSTANTS="$1"
if [ ! -f "$FIREBASE_CONSTANTS" ]; then
  echo "could not find FIREBASE_CONSTANTS: $FIREBASE_CONSTANTS"
  usage_and_exit
fi

cd "$(dirname "$FIREBASE_CONSTANTS")"
FIREBASE_CONSTANTS_DIR="$(pwd)"
FIREBASE_CONSTANTS_FILENAME="$(basename "$FIREBASE_CONSTANTS")"
FIREBASE_CONSTANTS_FILE="$FIREBASE_CONSTANTS_DIR/$FIREBASE_CONSTANTS_FILENAME"

cd "$WORK_DIR"


CRYPTO_TOKEN="$2"
if [ ! -f "$CRYPTO_TOKEN" ]; then
  echo "could not find CRYPTO_TOKEN: $CRYPTO_TOKEN"
  usage_and_exit
fi

cd "$(dirname "$CRYPTO_TOKEN")"
CRYPTO_TOKEN_DIR="$(pwd)"
CRYPTO_TOKEN_FILENAME="$(basename "$CRYPTO_TOKEN")"
CRYPTO_TOKEN_FILE="$CRYPTO_TOKEN_DIR/$CRYPTO_TOKEN_FILENAME"

cd "$WORK_DIR"

########## validate that the firebase constants file and the crypto token point to the same project

# Get the project id from the firebase constants file
echo "getting project id from firebase constants..."
FIREBASE_CONSTANTS_PROJECT_ID=$(cat "$FIREBASE_CONSTANTS_FILE" | python -c 'import json,sys; constants=json.load(sys.stdin); print(constants["projectId"])')
echo "project id: $FIREBASE_CONSTANTS_PROJECT_ID"

# Get the project id from the crypto token file
echo "getting project id from crypto token..."
CRYPTO_TOKEN_PROJECT_ID=$(cat "$CRYPTO_TOKEN_FILE" | python -c 'import json,sys; constants=json.load(sys.stdin); print(constants["project_id"])')
echo "project id: $CRYPTO_TOKEN_PROJECT_ID"

if [ "$FIREBASE_CONSTANTS_PROJECT_ID" != "$CRYPTO_TOKEN_PROJECT_ID" ]; then
  echo "the two project ids must match, check that you're deploying to the correct project"
  just_exit
fi

########## validate the cloud functions urls in the firebase constants file

echo ""
echo "verifying cloud functions urls from firebase constants..."

CLOUD_FUNCTIONS_LOCATION="europe-west1"

EXPECTED_URLS=( \
  "https://$CLOUD_FUNCTIONS_LOCATION-$FIREBASE_CONSTANTS_PROJECT_ID.cloudfunctions.net/Log" \
  "https://$CLOUD_FUNCTIONS_LOCATION-$FIREBASE_CONSTANTS_PROJECT_ID.cloudfunctions.net/Publish" \
  "https://$CLOUD_FUNCTIONS_LOCATION-$FIREBASE_CONSTANTS_PROJECT_ID.cloudfunctions.net/StatusZ" \
)

EXPECTED_KEYS=( \
  "logUrl" \
  "publishUrl" \
  "statuszUrl" \
)

for i in 0 1 2; do
  EXPECTED_URL=${EXPECTED_URLS[$i]}
  EXPECTED_KEY=${EXPECTED_KEYS[$i]}
  PYTHON_CODE="import json,sys; constants=json.load(sys.stdin); print(constants[\"$EXPECTED_KEY\"])"
  URL=$(cat "$FIREBASE_CONSTANTS_FILE" | python -c "$PYTHON_CODE")
  if [ "$URL" != "$EXPECTED_URL" ]; then
    echo ""
    echo "bad key $EXPECTED_KEY"
    echo "  got:      $URL"
    echo "  expected: $EXPECTED_URL"
    just_exit
  fi
done

echo "done! cloud functions urls look as expected"
echo ""

########## cd to the nook project directory and get the absolute path

cd "$(dirname "$0")"/..
NOOK_DIR="$(pwd)"

########## rebuild the webapp

echo ""

# Remove previous build if it exists
rm -rf public

# Build
cd webapp
echo "building webapp ..."
webdev build
echo "build complete"
mv build ../public
cd ..

echo ""

# Copy the constants in the build folder
cp $FIREBASE_CONSTANTS_FILE public/assets/firebase_constants.json

# Copy the latest commit sha1 hash on origin/master into the build folder
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
LASTEST_COMMIT_HASH=$(git rev-parse "$CURRENT_BRANCH")
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

# Deploy using the local firebase tool
echo "deploying to $FIREBASE_CONSTANTS_PROJECT_ID firebase..."
firebase deploy \
  --project $FIREBASE_CONSTANTS_PROJECT_ID \
  --public public \
  "${FIREBASE_DEPLOY_ARGS[@]}"
echo "firebase deploy result: $?"

# Deploy cloud functions if SKIP_CLOUD_FUNCTIONS is unset
if [ -z "$SKIP_CLOUD_FUNCTIONS" ]; then
  echo ""
  echo "deploying cloud functions..."
  cd cloud_functions

  for FUNCTION_NAME in Publish Log StatusZ
  do
  gcloud --project $CRYPTO_TOKEN_PROJECT_ID functions deploy \
    $FUNCTION_NAME \
    --entry-point $FUNCTION_NAME \
    --runtime python37 \
    --allow-unauthenticated \
    --region=europe-west1 \
    --trigger-http
  done

  cd ..
  echo ""
  echo "done updating cloud functions"
else
  echo ""
  echo "skipping deploying cloud functions"
fi

echo ""
echo "updating nook webapp metadata..."
cd tool
pipenv run python json_to_firebase.py "$CRYPTO_TOKEN_FILE" ../public_metadata_nook_app.json
cd ..

echo ""
echo "deployment complete"
