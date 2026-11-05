const express = require('express')
const version = process.version.match(/^v(\d+\.\d+)/)[1]
const app = express()

const port = process.env.PORT || 3000;

app.disable('x-powered-by')

app.get('/', (req, res) => res.send(`Hello World from node ${version}`))

app.get('/health/liveness', (req, res) => res.status(200).json({ status: 'alive' }))

app.get('/health/startup', (req, res) => res.status(200).json({ status: 'started' }))

app.get('/health/readiness', (req, res) => res.status(200).json({ status: 'ready' }))

const server = app.listen(port, (err) => {
    if (err) {
      console.log('Error::', err);
      process.exit(1);
    }
    console.log(`App listening on port ${port}`);
});

// Node runs as PID 1 inside the container: without this, `docker stop` waits 10s and sends SIGKILL
for (const signal of ['SIGTERM', 'SIGINT']) {
  process.on(signal, () => {
    console.log(`${signal} received, shutting down`);
    server.close(() => process.exit(0));
  });
}
