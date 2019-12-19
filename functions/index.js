// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to authenticate publish requests.
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

    fbUserIdToken = data.fbUserIdToken;
    console.log(`Validating: ${fbUserIdToken}`);

    // Validate the user making the request
    admin.auth()
      .verifyIdToken(data.fbUserIdToken)
      .then((decodedToken) => {
        // Lookup the user
        userId = decodedToken.uid;
        console.log(`Looking up: ${userId}`);
        return admin.auth().getUser(userId);
      }).then((user) => {
        // Publish the message
        console.log(`${user.email} publishing topic: ${topic} payload: ${payload}`);
        publisher = topic.publisher();
        return publisher.publish(Buffer.from(JSON.stringify(payload)));
      }).then(() => {
        // Send response indicating success
        return res.status(200).send('Message published.');
      }).catch(err => {
        // Log the error and respond indicating failure
        console.error(err);
        res.status(500).send(err);
      });
    });
  });

function reportMissingField(res, fieldName) {
  errorMsg = `Missing ${fieldName} field in request body.`;
  console.error(Error(errorMsg));
  res.status(500).json({"error": errorMsg});
}
