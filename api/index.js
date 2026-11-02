const url = require('url');
const apiRouter = require('../backend/routes/api_router');

module.exports = async (req, res) => {
  try {
    const parsed = url.parse(req.url, true);
    const originalUrl = parsed.query._route ||
                        req.headers['x-forwarded-url'] ||
                        req.headers['x-matched-path'] ||
                        req.url;
    req.url = originalUrl;

    const pathname = (url.parse(req.url).pathname || '/').toLowerCase();
    if (pathname === '/' || pathname === '') {
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
      res.end(JSON.stringify({ ok: false, error: `Endpoint not found: ${req.url}` }));
    }
  } catch (err) {
    console.error('[Vercel Handler Error]', err);
    if (!res.writableEnded) {
      res.writeHead(500, {
        'Content-Type': 'application/json; charset=UTF-8',
        'Access-Control-Allow-Origin': '*',
      });
      res.end(JSON.stringify({ ok: false, error: err.message }));
    }
  }
};
