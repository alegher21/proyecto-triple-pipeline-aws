const assert = require('assert');
const app = require('./server');

const server = app.listen(0, async () => {
  const port = server.address().port;
  try {
    const res = await fetch(`http://127.0.0.1:${port}/api/health`);
    const data = await res.json();
    assert.strictEqual(res.status, 200);
    assert.strictEqual(data.status, 'OK');
    console.log('PRUEBA EXITOSA: Endpoint /api/health responde OK');
    server.close();
    process.exit(0);
  } catch (err) {
    console.error('FALLO EN PRUEBA:', err);
    server.close();
    process.exit(1);
  }
});
