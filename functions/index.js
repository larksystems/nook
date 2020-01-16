// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
// See https://firebase.google.com/docs/functions/get-started
const functions = require('firebase-functions');

// The Firebase Admin SDK to authenticate incomming publish requests
// before calling google-cloud/pubsub.
const admin = require('firebase-admin');
admin.initializeApp();

const cors = require('cors')({origin: true});
const {PubSub} = require('@google-cloud/pubsub');
const pubsub = new PubSub();

const Buffer = require('safe-buffer').Buffer;

exports.Log = functions.https.onRequest((request, response) => {
    cors(request, response, () => {
        logData = 
        {
            "body" : request.body,
            "query" : request.query,
            "ip" : request.ip,
            "url" : request.originalUrl,
            "params" : request.params,
            "method" : request.method,
            "raw_headers" : request.rawHeaders,
        }

        console.log(logData);
        response.send("Ack");
    });
});

exports.Publish = functions.https.onRequest((req, res) => {
  cors(req, res, () => {
    console.log(`Request body ${req.body}`);
    data = JSON.parse(req.body);

    if (!data.fbUserIdToken) {
      reportMissingField(res, 'fbUserIdToken');
      return;
    } else if (!data.topic) {
      reportMissingField(res, 'topic');
      return;
    } else if (!data.payload) {
      reportMissingField(res, 'payload');
      return;
    }

    // References an existing topic
    const topic = pubsub.topic(data.topic);
    const payload = {
        payload: data.payload,
    };

    // Validate the user making the request then forward the pub/sub message to google cloud.

    fbUserIdToken = data.fbUserIdToken;
    console.log(`Validating: ${fbUserIdToken}`);

    // Step 1) Decode and validate the encrypted/signed JWT (JSON web token)
    // If token is valid, returns a promise which returns a decoded token passed into next "then" block.
    // If token is NOT valid, then an exception is thrown.
    // See https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_the_firebase_admin_sdk
    admin.auth()
      .verifyIdToken(data.fbUserIdToken)
      .then((decodedToken) => {
        userId = decodedToken.uid;
        console.log(`Looking up: ${userId}`);
        // Step 2) Look up the user to obtain the email address for logging purposes.
        // Returns promise which returns a UserRecord passed as "user" into next "then" block.
        // https://firebase.google.com/docs/reference/admin/node/admin.auth.UserRecord.html
        return admin.auth().getUser(userId);
      }).then((user) => {
        // Publish the message
        console.log(`${user.email} publishing topic: ${topic} payload: ${payload}`);
        // console.log(objDetails("topic", topic));
        publisher = topic.publisher;
        return publisher.publish(Buffer.from(JSON.stringify(payload)));
      }).then(() => {
        // Send response indicating success
        return res.status(200).send('Message published.');
      }).catch(err => {
        // Log the error and respond indicating failure
        console.error(err);
        return res.status(500).send(err);
      });
    });
  });

function reportMissingField(res, fieldName) {
  errorMsg = `Missing ${fieldName} field in request body.`;
  console.error(Error(errorMsg));
  res.status(500).json({"error": errorMsg});
}

// Utility function for debugging that returns a description an object's properties and methods
function objDetails(objName, obj) {
  let properties = new Set();
  let currentObj = obj;
  do {
    Object.getOwnPropertyNames(currentObj).map(item => properties.add(item))
  } while ((currentObj = Object.getPrototypeOf(currentObj)));
  let description = `${objName} object details:`;
  let items = [...properties.keys()];
  items.sort();
  items.forEach(item => description = description.concat("\n", item, " --> ", typeof obj[item]));
  return description;
}
