require('dotenv').config();
const fs = require('fs');
const path = require('path');
const https = require('https');

function post(url, data) {
  return new Promise((resolve, reject) => {
    const payload = new URLSearchParams(data).toString();
    const u = new URL(url);
    const req = https.request({
      hostname: u.hostname,
      path: u.pathname + u.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(payload)
      }
    }, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, body }));
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, body }));
    }).on('error', reject);
  });
}

async function main() {
  const apiKey = process.env.CELOSCAN_API_KEY;
  const address = process.argv[2];
  if (!apiKey) throw new Error('Missing CELOSCAN_API_KEY');
  if (!address) throw new Error('Usage: node scripts/verify-celoscan.js <address>');
  const source = fs.readFileSync(path.join(__dirname, '..', 'contracts', 'CitadelVault.sol'), 'utf8');

  const compilerversion = 'v0.8.20+commit.a1b79de6';
  const verifyUrl = 'https://api.celoscan.io/api';

  const payload = {
    apikey: apiKey,
    module: 'contract',
    action: 'verifysourcecode',
    contractaddress: address,
    sourceCode: source,
    codeformat: 'solidity-single-file',
    contractname: 'CitadelVault',
    compilerversion,
    optimizationUsed: '0',
    runs: '200'
  };

  const res = await post(verifyUrl, payload);
  if (res.statusCode !== 200) throw new Error('HTTP ' + res.statusCode + ': ' + res.body);
  const j = JSON.parse(res.body);
  if (j.status !== '1') throw new Error('Verify error: ' + j.result);
  const guid = j.result;
  console.log('Submitted, guid:', guid);

  for (let i = 0; i < 12; i++) {
    await new Promise(r => setTimeout(r, 5000));
    const statusUrl = `${verifyUrl}?module=contract&action=checkverifystatus&guid=${guid}&apikey=${apiKey}`;
    const s = await get(statusUrl);
    const sj = JSON.parse(s.body);
    console.log('Status:', sj.result || sj.message);
    if (sj.status === '1') {
      console.log('Verified');
      return;
    }
  }
  throw new Error('Verification status timed out');
}

main().catch((e) => {
  console.error(e.message || e);
  process.exitCode = 1;
});
