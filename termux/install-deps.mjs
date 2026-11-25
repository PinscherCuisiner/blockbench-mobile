// Installs only the dependencies the *web* build needs. The full package.json also
// pulls in Electron, electron-builder, typedoc, TypeScript... which are huge, useless
// for a browser build, and whose install scripts fail on Android/Termux.
// package.json and package-lock.json are restored afterwards.
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const pkgPath = path.join(root, 'package.json');
const lockPath = path.join(root, 'package-lock.json');

const DROP = [/^electron/, /^@electron\//, /^@types\//, /^typedoc/, /^typescript$/, /^ts-unused-exports$/];
const keep = (deps = {}) => Object.fromEntries(
	Object.entries(deps).filter(([name]) => !DROP.some(re => re.test(name)))
);

const originalPkg = fs.readFileSync(pkgPath, 'utf8');
const originalLock = fs.existsSync(lockPath) ? fs.readFileSync(lockPath, 'utf8') : null;

function restore() {
	fs.writeFileSync(pkgPath, originalPkg);
	if (originalLock !== null) fs.writeFileSync(lockPath, originalLock);
}
process.on('SIGINT', () => { restore(); process.exit(130); });
process.on('SIGTERM', () => { restore(); process.exit(143); });

let status = 1;
try {
	const pkg = JSON.parse(originalPkg);
	pkg.devDependencies = keep(pkg.devDependencies);
	pkg.dependencies = keep(pkg.dependencies);
	fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, '\t'));

	const result = spawnSync('npm', [
		'install', '--ignore-scripts', '--no-audit', '--no-fund', '--loglevel=error',
	], {
		cwd: root,
		stdio: 'inherit',
		env: { ...process.env, ELECTRON_SKIP_BINARY_DOWNLOAD: '1' },
	});
	status = result.status ?? 1;
} finally {
	restore();
}
process.exit(status);
