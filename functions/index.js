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
    console.log(`Execution of publish starting`);
    console.log(`Request body ${req.body}`);
    data = JSON.parse(req.body);

    if (!data.topic) {
        console.log(`Topic not provided`);

      res
        .status(500)
        .send(
          new Error(
            'Topic not provided. Make sure you have a "topic" property in your request'
          )
        );
      return;
    } else if (!data.message) {
        console.log(`Message not provided`);
      res
        .status(500)
        .send(
          new Error(
            'Message not provided. Make sure you have a "message" property in your request'
          )
        );
      return;
    }

    // References an existing topic
    const topic = pubsub.topic(data.topic);
    const message = {
      data: {
        message: data.message,
      },
    };

    console.log(`Publishing Topic: ${topic} Message: ${message}`);

    publisher = topic.publisher();
  
    // Publishes a message
    publisher
      .publish(Buffer.from(JSON.stringify(message)))
      .then(() => res.status(200).send('Message published.'))
      .catch(err => {
        console.error(err);
        res.status(500).send(err);
        return Promise.reject(err);
      });
    });
  });
