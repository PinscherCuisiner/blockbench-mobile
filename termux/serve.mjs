// Zero-dependency static file server for the built Blockbench web/PWA app.
// Usage: node termux/serve.mjs [--port 8080] [--host 127.0.0.1|0.0.0.0]
// http://localhost counts as a secure context, so the service worker and
// "Install app" / "Add to Home screen" work in Chrome on Android.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const arg = (name, fallback) => {
	const i = args.indexOf('--' + name);
	return i >= 0 && args[i + 1] ? args[i + 1] : fallback;
};
const port = Number(arg('port', process.env.PORT || 8080));
const host = arg('host', process.env.HOST || '127.0.0.1');

const MIME = {
	'.html': 'text/html; charset=utf-8',
	'.js': 'text/javascript; charset=utf-8',
	'.mjs': 'text/javascript; charset=utf-8',
	'.css': 'text/css; charset=utf-8',
	'.json': 'application/json; charset=utf-8',
	'.webmanifest': 'application/manifest+json; charset=utf-8',
	'.map': 'application/json; charset=utf-8',
	'.svg': 'image/svg+xml',
	'.png': 'image/png',
	'.jpg': 'image/jpeg',
	'.jpeg': 'image/jpeg',
	'.gif': 'image/gif',
	'.ico': 'image/x-icon',
	'.woff': 'font/woff',
	'.woff2': 'font/woff2',
	'.ttf': 'font/ttf',
	'.otf': 'font/otf',
	'.wasm': 'application/wasm',
	'.glsl': 'text/plain; charset=utf-8',
	'.txt': 'text/plain; charset=utf-8',
	'.bbtheme': 'application/json; charset=utf-8',
	'.bbkeymap': 'application/json; charset=utf-8',
};

if (!fs.existsSync(path.join(root, 'dist', 'bundle.js'))) {
	console.error('dist/bundle.js not found. Run the build first:  npm run build-mobile');
	process.exit(1);
}

const server = http.createServer((req, res) => {
	let pathname;
	try {
		pathname = decodeURIComponent(new URL(req.url, 'http://x').pathname);
	} catch {
		res.writeHead(400).end('Bad request');
		return;
	}
	if (pathname.endsWith('/')) pathname += 'index.html';
	const file = path.normalize(path.join(root, pathname));
	// Never serve anything outside the project, nor dev-only folders
	const rel = path.relative(root, file);
	if (rel.startsWith('..') || path.isAbsolute(rel) || /^(node_modules|\.git|termux)(\/|$)/.test(rel)) {
		res.writeHead(403).end('Forbidden');
		return;
	}
	fs.stat(file, (err, stat) => {
		if (err || !stat.isFile()) {
			res.writeHead(404).end('Not found');
			return;
		}
		const headers = {
			'Content-Type': MIME[path.extname(file).toLowerCase()] || 'application/octet-stream',
			'Content-Length': stat.size,
			// The service worker file must never be cached by the HTTP cache, otherwise
			// app updates would not be picked up. Everything else is revalidated.
			'Cache-Control': 'no-cache',
		};
		if (path.basename(file) === 'service_worker.js') headers['Service-Worker-Allowed'] = '/';
		res.writeHead(200, headers);
		if (req.method === 'HEAD') return res.end();
		fs.createReadStream(file).on('error', () => res.destroy()).pipe(res);
	});
});

server.on('error', (err) => {
	if (err.code === 'EADDRINUSE') {
		console.error(`Port ${port} is already in use. Blockbench may already be running, or pick another port: --port ${port + 1}`);
	} else {
		console.error(err);
	}
	process.exit(1);
});

server.listen(port, host, () => {
	console.log(`Blockbench is running on  http://${host === '0.0.0.0' ? 'localhost' : host}:${port}`);
	console.log('Open it in Chrome, then menu > "Install app" / "Add to Home screen".');
	console.log('Press Ctrl+C to stop.');
});
