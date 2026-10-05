import { spawn } from 'child_process';
import http from 'http';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const jarPath = path.resolve(__dirname, 'firebase-database-emulator.jar');

function isEmulatorUp() {
  return new Promise((resolve) => {
    const req = http.get('http://127.0.0.1:9000/.inspect/coverage.json', (res) => {
      resolve(res.statusCode === 200);
    });
    req.on('error', () => resolve(false));
    req.setTimeout(1000, () => {
      req.destroy();
      resolve(false);
    });
  });
}

async function waitForEmulator(timeoutMs = 15000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if (await isEmulatorUp()) return true;
    await new Promise((r) => setTimeout(r, 500));
  }
  return false;
}

async function main() {
  let emulatorProc = null;
  const alreadyRunning = await isEmulatorUp();

  if (!alreadyRunning) {
    console.log('[Runner] Menjalankan Firebase Database Emulator di 127.0.0.1:9000...');
    emulatorProc = spawn('java', ['-jar', jarPath, '--host', '127.0.0.1', '--port', '9000'], {
      stdio: 'ignore',
      detached: false,
    });

    const ready = await waitForEmulator();
    if (!ready) {
      console.error('[Runner] Gagal menyalakan Firebase Database Emulator.');
      if (emulatorProc) emulatorProc.kill();
      process.exit(1);
    }
    console.log('[Runner] Firebase Database Emulator siap!');
  } else {
    console.log('[Runner] Firebase Database Emulator sudah berjalan di port 9000.');
  }

  console.log('[Runner] Menjalankan Security Rules Unit Test Suite...');
  const testProc = spawn('node', ['--test', path.resolve(__dirname, 'rules.test.js')], {
    stdio: 'inherit',
  });

  testProc.on('exit', (code) => {
    if (emulatorProc) {
      console.log('[Runner] Menghentikan Firebase Database Emulator...');
      emulatorProc.kill();
    }
    process.exit(code || 0);
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
