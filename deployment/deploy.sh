# Exit immediately if a command exits with a non-zero status
set -e
if [ $# -ne 1 ]; then
    echo "Usage: deploy.sh path/to/firebase/deployment/constants.json"
    exit 1
fi

PATH_TO_CONSTANTS_FILE="$1"

# Remove previous build if it exists
rm -rf public

# Build
cd webapp
webdev build
mv build ../public
cd ..

# Copy the constants in the build folder
cp $PATH_TO_CONSTANTS_FILE public/assets/firebase_constants.json

# Copy the latest commit sha1 hash on origin/master into the build folder
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
LASTEST_COMMIT_HASH=$(git rev-parse $CURRENT_BRANCH)
echo "{\"latestCommitHash\": \"$LASTEST_COMMIT_HASH\"}" > public/assets/latest_commit_hash.json

# Get the project id
PROJECT_ID=$(cat $PATH_TO_CONSTANTS_FILE | python -c 'import json,sys; constants=json.load(sys.stdin); print(constants["projectId"])')

# Deploy
firebase deploy --project $PROJECT_ID --public public
