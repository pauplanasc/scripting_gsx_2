const http = require('http');
const redis = require('redis');

const port = process.env.PORT || 3000;
const redisHost = process.env.REDIS_HOST || 'redis';
const message = process.env.APP_MESSAGE || 'Hello from Compose!';

// Conectar a la base de datos Redis
const client = redis.createClient({
    url: `redis://${redisHost}:6379`
});

client.on('error', err => console.log('Redis Client Error', err));
client.connect();

const server = http.createServer(async (req, res) => {
  try {
    // Incrementa el contador en la base de datos
    let visits = await client.incr('visits');
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    res.end(`${message}\nEres el visitante numero: ${visits}\n`);
  } catch (e) {
    res.statusCode = 500;
    res.end('Error conectando a la base de datos\n');
  }
});

server.listen(port, () => {
  console.log(`Server running at port ${port}`);
});