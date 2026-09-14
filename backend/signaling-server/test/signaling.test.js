'use strict';

const WebSocket = require('ws');
const { spawn } = require('child_process');
const assert = require('assert');
const path = require('path');

const PORT = 8089;

function runTests() {
  console.log('--- Starting Signaling Server Unit / E2E Test ---');

  // Spawn server on custom port
  const serverProcess = spawn('node', [path.join(__dirname, '../src/server.js')], {
    env: { ...process.env, PORT: PORT.toString() },
    stdio: 'inherit',
  });

  function cleanupAndExit(code) {
    serverProcess.kill();
    process.exit(code);
  }

  // Wait 1 second for server to bind
  setTimeout(async () => {
    try {
      const url = `ws://127.0.0.1:${PORT}`;

      // 1. Device A connects
      const wsA = new WebSocket(url);
      await new Promise((res, rej) => {
        wsA.on('open', res);
        wsA.on('error', rej);
      });
      console.log('✓ Device A connected');

      // 2. Device A creates session
      const sessionId = 'test-session-' + Date.now();
      wsA.send(JSON.stringify({ type: 'createSession', sessionId }));

      await new Promise((res) => {
        wsA.once('message', (data) => {
          const msg = JSON.parse(data.toString());
          assert.strictEqual(msg.type, 'sessionReady');
          assert.strictEqual(msg.sessionId, sessionId);
          res();
        });
      });
      console.log('✓ Session created successfully on server');

      // 3. Device B connects and joins session
      const wsB = new WebSocket(url);
      await new Promise((res, rej) => {
        wsB.on('open', res);
        wsB.on('error', rej);
      });
      console.log('✓ Device B connected');

      wsB.send(JSON.stringify({ type: 'joinSession', sessionId }));
      await new Promise((res) => {
        wsB.once('message', (data) => {
          const msg = JSON.parse(data.toString());
          assert.strictEqual(msg.type, 'sessionReady');
          assert.strictEqual(msg.sessionId, sessionId);
          res();
        });
      });
      console.log('✓ Device B joined session');

      // 4. Device A sends WebRTC offer
      const testOfferSdp = 'v=0\r\no=alice 12345 2 IN IP4 127.0.0.1';
      wsA.send(JSON.stringify({
        type: 'offer',
        sessionId,
        data: { sdp: testOfferSdp },
      }));

      await new Promise((res) => {
        wsB.once('message', (data) => {
          const msg = JSON.parse(data.toString());
          assert.strictEqual(msg.type, 'offer');
          assert.strictEqual(msg.data.sdp, testOfferSdp);
          res();
        });
      });
      console.log('✓ Offer relayed from A to B');

      // 5. Device B sends WebRTC answer
      const testAnswerSdp = 'v=0\r\no=bob 67890 2 IN IP4 127.0.0.1';
      wsB.send(JSON.stringify({
        type: 'answer',
        sessionId,
        data: { sdp: testAnswerSdp },
      }));

      await new Promise((res) => {
        wsA.once('message', (data) => {
          const msg = JSON.parse(data.toString());
          assert.strictEqual(msg.type, 'answer');
          assert.strictEqual(msg.data.sdp, testAnswerSdp);
          res();
        });
      });
      console.log('✓ Answer relayed from B to A');

      // 6. Device A sends ICE Candidate
      const testCandidate = { candidate: 'candidate:1 1 UDP 2122252543 192.168.1.5 50000 typ host', sdpMid: '0', sdpMLineIndex: 0 };
      wsA.send(JSON.stringify({
        type: 'iceCandidate',
        sessionId,
        data: testCandidate,
      }));

      await new Promise((res) => {
        wsB.once('message', (data) => {
          const msg = JSON.parse(data.toString());
          assert.strictEqual(msg.type, 'iceCandidate');
          assert.strictEqual(msg.data.candidate, testCandidate.candidate);
          res();
        });
      });
      console.log('✓ ICE Candidate relayed from A to B');

      wsA.close();
      wsB.close();

      console.log('\n=========================================');
      console.log(' ALL SIGNALING TESTS PASSED PERFECTLY! ');
      console.log('=========================================\n');
      cleanupAndExit(0);
    } catch (err) {
      console.error('Test failed:', err);
      cleanupAndExit(1);
    }
  }, 1000);
}

runTests();
