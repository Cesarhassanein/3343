const apiRouter = require('../backend/routes/api_router');

module.exports = async (req, res) => {
  try {
    const url = req.url.split('?')[0];
    if (url === '/' || url === '') {
      res.writeHead(200, {
        'Content-Type': 'application/json; charset=UTF-8',
        'Access-Control-Allow-Origin': '*',
      });
      res.end(JSON.stringify({
        ok: true,
        service: 'Wadiq Backend API Proxy',
        status: 'online',
        health: '/api/health',
      }));
      return;
    }

    const handled = await apiRouter.handle(req, res);
    if (!handled && !res.writableEnded) {
      res.writeHead(404, {
        'Content-Type': 'application/json; charset=UTF-8',
        'Access-Control-Allow-Origin': '*',
      });
      res.end(JSON.stringify({ ok: false, error: 'Endpoint not found' }));
    }
  } catch (err) {
    if (!res.writableEnded) {
      res.writeHead(500, {
        'Content-Type': 'application/json; charset=UTF-8',
        'Access-Control-Allow-Origin': '*',
      });
      res.end(JSON.stringify({ ok: false, error: err.message }));
    }
  }
};
