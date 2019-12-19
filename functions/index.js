const functions = require('firebase-functions');
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

    console.log(`Publishing Topic: ${topic} Payload: ${payload}`);

    publisher = topic.publisher();
  
    // Publishes a message
    publisher
      .publish(Buffer.from(JSON.stringify(payload)))
      .then(() => res.status(200).send('Message published.'))
      .catch(err => {
        console.error(err);
        res.status(500).send(err);
        return Promise.reject(err);
      });
    });
  });

function reportMissingField(res, fieldName) {
  errorMsg = `Missing ${fieldName} field in request body.`;
  console.error(Error(errorMsg));
  res.status(500).json({"error": errorMsg});
}
