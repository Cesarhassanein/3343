const url = require('url');
const apiRouter = require('../backend/routes/api_router');

module.exports = async (req, res) => {
  try {
    // Determine the actual intended URL
    let targetUrl = req.url || '/';

    // If query string has _route from rewrite, use it
    const parsed = url.parse(targetUrl, true);
    if (parsed.query && parsed.query._route) {
      targetUrl = parsed.query._route;
    } else if (req.headers['x-matched-path'] && req.headers['x-matched-path'].startsWith('/api/')) {
      targetUrl = req.headers['x-matched-path'];
    } else if (req.headers['x-forwarded-url']) {
      targetUrl = req.headers['x-forwarded-url'];
    }

    // If still pointing to index.js or [...all].js, strip it to /api/health or requested path
    if (targetUrl === '/api/index.js' || targetUrl === '/api/[...all].js' || targetUrl === '/api' || targetUrl === '/api/') {
      targetUrl = '/api/health';
    }

    req.url = targetUrl;

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
