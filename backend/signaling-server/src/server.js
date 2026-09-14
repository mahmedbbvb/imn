'use strict';

const http = require('http');
const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

const PORT = process.env.PORT || 8080;
const SESSION_TTL_MS = 10 * 60 * 1000; // 10 minutes

// ── Session store ────────────────────────────────────────────────────────────
const sessions = new Map();

// ── Device registry (for contact requests) ───────────────────────────────────
const devices = new Map();

// ── HTTP Server (for Railway health checks) ──────────────────────────────────
const httpServer = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      clients: wss ? wss.clients.size : 0,
      sessions: sessions.size,
      devices: devices.size,
      uptime: process.uptime(),
    }));
  } else {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Imn Signaling Server');
  }
});

// ── WebSocket Server ─────────────────────────────────────────────────────────
const wss = new WebSocket.Server({ server: httpServer });

httpServer.listen(PORT, () => {
  console.log(`[Imn Signaling] HTTP+WS listening on port ${PORT}`);
});


wss.on('connection', (ws, req) => {
  ws.id = uuidv4();
  ws.sessionId = null;
  ws.deviceId = null;
  ws.isAlive = true;

  const ip = req.socket.remoteAddress;
  console.log(`[+] Client connected: ${ws.id} (${ip})`);

  ws.on('pong', () => { ws.isAlive = true; });

  ws.on('message', (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch {
      sendError(ws, 'Invalid JSON');
      return;
    }

    const { type, sessionId, deviceId, targetDeviceId, data } = msg;
    console.log(`[MSG] ${ws.id} → type=${type} session=${sessionId} device=${deviceId}`);

    switch (type) {
      case 'ping':
        send(ws, { type: 'pong' });
        break;

      // ── Device Registration ──────────────────────────────────────────────
      case 'register':
        handleRegister(ws, deviceId);
        break;

      // ── Contact Request (device-id-based routing) ────────────────────────
      case 'contactRequest':
        handleContactRequest(ws, targetDeviceId, data);
        break;

      case 'contactRequestResponse':
        handleContactRequestResponse(ws, targetDeviceId, data);
        break;

      // ── WebRTC Session-based Signaling ───────────────────────────────────
      case 'createSession':
        handleCreateSession(ws, sessionId);
        break;

      case 'joinSession':
        handleJoinSession(ws, sessionId);
        break;

      case 'offer':
        handleOffer(ws, sessionId, data);
        break;

      case 'answer':
        handleAnswer(ws, sessionId, data);
        break;

      case 'iceCandidate':
        handleIceCandidate(ws, sessionId, data);
        break;

      case 'chatMessage':
        handleChatMessage(ws, targetDeviceId, data);
        break;

      case 'callSignal':
        handleCallSignal(ws, targetDeviceId, data);
        break;

      default:
        sendError(ws, `Unknown type: ${type}`);
    }
  });

  ws.on('close', () => {
    console.log(`[-] Client disconnected: ${ws.id}`);

    // Remove from device registry
    if (ws.deviceId && devices.get(ws.deviceId) === ws) {
      devices.delete(ws.deviceId);
      console.log(`[DEVICE] Unregistered: ${ws.deviceId}`);
    }

    // Clean up session if host disconnects
    if (ws.sessionId) {
      const session = sessions.get(ws.sessionId);
      if (session && session.offer === ws) {
        closeSession(ws.sessionId);
      }
    }
  });

  ws.on('error', (err) => {
    console.error(`[ERROR] ${ws.id}:`, err.message);
  });
});

// ── Device Registration ───────────────────────────────────────────────────────

function handleRegister(ws, deviceId) {
  if (!deviceId) {
    sendError(ws, 'deviceId required for registration');
    return;
  }
  // If device was already registered with another connection, close old one
  const existing = devices.get(deviceId);
  if (existing && existing !== ws && existing.readyState === WebSocket.OPEN) {
    existing.close();
  }
  devices.set(deviceId, ws);
  ws.deviceId = deviceId;
  send(ws, { type: 'registered', deviceId });
  console.log(`[DEVICE] Registered: ${deviceId} (${ws.id})`);
}

// ── Contact Request Handlers ──────────────────────────────────────────────────

function handleContactRequest(ws, targetDeviceId, data) {
  if (!targetDeviceId) {
    sendError(ws, 'targetDeviceId required');
    return;
  }
  const targetWs = devices.get(targetDeviceId);
  if (!targetWs || targetWs.readyState !== WebSocket.OPEN) {
    // Target not online — notify sender
    send(ws, {
      type: 'contactRequestStatus',
      data: { status: 'offline', targetDeviceId },
    });
    console.log(`[CONTACT_REQ] Target offline: ${targetDeviceId}`);
    return;
  }
  // Forward request to target
  send(targetWs, {
    type: 'contactRequest',
    fromDeviceId: ws.deviceId,
    data,
  });
  send(ws, {
    type: 'contactRequestStatus',
    data: { status: 'delivered', targetDeviceId },
  });
  console.log(`[CONTACT_REQ] Forwarded ${ws.deviceId} → ${targetDeviceId}`);
}

function handleContactRequestResponse(ws, targetDeviceId, data) {
  if (!targetDeviceId) {
    sendError(ws, 'targetDeviceId required');
    return;
  }
  const targetWs = devices.get(targetDeviceId);
  if (!targetWs || targetWs.readyState !== WebSocket.OPEN) {
    console.log(`[CONTACT_RESP] Target offline: ${targetDeviceId}`);
    return;
  }
  // Forward response (accepted/rejected) to requester
  send(targetWs, {
    type: 'contactRequestResponse',
    fromDeviceId: ws.deviceId,
    data,
  });
  console.log(`[CONTACT_RESP] Forwarded ${ws.deviceId} → ${targetDeviceId} accepted=${data && data.accepted}`);
}

// ── Encrypted Chat Relay ──────────────────────────────────────────────────────

function handleChatMessage(ws, targetDeviceId, data) {
  if (!targetDeviceId) {
    sendError(ws, 'targetDeviceId required for chatMessage');
    return;
  }
  const targetWs = devices.get(targetDeviceId);
  if (!targetWs || targetWs.readyState !== WebSocket.OPEN) {
    send(ws, {
      type: 'chatMessageStatus',
      data: { status: 'offline', messageId: data && data.messageId },
    });
    return;
  }
  send(targetWs, {
    type: 'chatMessage',
    fromDeviceId: ws.deviceId,
    data,
  });
  send(ws, {
    type: 'chatMessageStatus',
    data: { status: 'delivered', messageId: data && data.messageId },
  });
  console.log(`[CHAT_RELAY] ${ws.deviceId} → ${targetDeviceId} msgId=${data && data.messageId}`);
}

// ── Call Signaling Relay ──────────────────────────────────────────────────────

function handleCallSignal(ws, targetDeviceId, data) {
  if (!targetDeviceId) {
    sendError(ws, 'targetDeviceId required for callSignal');
    return;
  }
  const targetWs = devices.get(targetDeviceId);
  if (!targetWs || targetWs.readyState !== WebSocket.OPEN) {
    send(ws, {
      type: 'callSignalStatus',
      data: { status: 'offline', callAction: data && data.action },
    });
    return;
  }
  send(targetWs, {
    type: 'callSignal',
    fromDeviceId: ws.deviceId,
    data,
  });
  console.log(`[CALL_SIGNAL] ${ws.deviceId} → ${targetDeviceId} action=${data && data.action}`);
}

// ── WebRTC Session Handlers ───────────────────────────────────────────────────

function handleCreateSession(ws, sessionId) {
  if (!sessionId) {
    sendError(ws, 'sessionId required');
    return;
  }
  if (sessions.has(sessionId)) {
    // Allow re-creation (idempotent) if same ws
    const existing = sessions.get(sessionId);
    if (existing.offer === ws) {
      send(ws, { type: 'sessionReady', sessionId });
      return;
    }
    sendError(ws, 'Session already exists');
    return;
  }

  const timer = setTimeout(() => {
    console.log(`[EXPIRE] Session ${sessionId}`);
    closeSession(sessionId);
  }, SESSION_TTL_MS);

  sessions.set(sessionId, {
    offer: ws,
    answer: null,
    createdAt: Date.now(),
    timer,
    pendingCandidates: [],
    offerSdp: null,
  });

  ws.sessionId = sessionId;
  send(ws, { type: 'sessionReady', sessionId });
  console.log(`[SESSION] Created: ${sessionId}`);
}

function handleJoinSession(ws, sessionId) {
  const session = sessions.get(sessionId);
  if (!session) {
    sendError(ws, 'Session not found or expired');
    return;
  }
  if (session.answer && session.answer !== ws) {
    sendError(ws, 'Session already has two peers');
    return;
  }

  session.answer = ws;
  ws.sessionId = sessionId;

  send(ws, { type: 'sessionReady', sessionId });

  // If offer SDP is already available, forward it immediately
  if (session.offerSdp) {
    send(ws, {
      type: 'offer',
      sessionId,
      data: { sdp: session.offerSdp },
    });
    console.log(`[SESSION] Forwarded buffered offer to joiner: ${sessionId}`);
  }

  // Flush any buffered ICE candidates to the answer side
  if (session.pendingOfferCandidates && session.pendingOfferCandidates.length > 0) {
    for (const c of session.pendingOfferCandidates) {
      send(ws, { type: 'iceCandidate', sessionId, data: c });
    }
    session.pendingOfferCandidates = [];
  }

  console.log(`[SESSION] Joined: ${sessionId}`);
}

function handleOffer(ws, sessionId, data) {
  const session = sessions.get(sessionId);
  if (!session) { sendError(ws, 'Session not found'); return; }

  // Store offer SDP for late joiners
  session.offerSdp = data && data.sdp;

  // If responder is already connected, forward immediately
  if (session.answer) {
    send(session.answer, { type: 'offer', sessionId, data });
  }
  // else: stored above and will be sent when answer joins
}

function handleAnswer(ws, sessionId, data) {
  const session = sessions.get(sessionId);
  if (!session) { sendError(ws, 'Session not found'); return; }
  if (!session.offer) { sendError(ws, 'No offerer in session'); return; }

  // Forward answer to the offerer (Device A)
  send(session.offer, { type: 'answer', sessionId, data });

  // Flush any buffered ICE candidates from answer side to offer side
  if (session.pendingAnswerCandidates && session.pendingAnswerCandidates.length > 0) {
    for (const c of session.pendingAnswerCandidates) {
      send(session.offer, { type: 'iceCandidate', sessionId, data: c });
    }
    session.pendingAnswerCandidates = [];
  }
}

function handleIceCandidate(ws, sessionId, data) {
  const session = sessions.get(sessionId);
  if (!session) return;

  const isOffer = ws === session.offer;
  const peer = isOffer ? session.answer : session.offer;

  if (peer && peer.readyState === WebSocket.OPEN) {
    send(peer, { type: 'iceCandidate', sessionId, data });
  } else {
    // Buffer candidates until peer connects
    if (isOffer) {
      session.pendingOfferCandidates = session.pendingOfferCandidates || [];
      session.pendingOfferCandidates.push(data);
    } else {
      session.pendingAnswerCandidates = session.pendingAnswerCandidates || [];
      session.pendingAnswerCandidates.push(data);
    }
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function send(ws, msg) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(msg));
  }
}

function sendError(ws, message) {
  send(ws, { type: 'error', data: { message } });
  console.warn(`[ERROR] Sent to ${ws.id}: ${message}`);
}

function closeSession(sessionId) {
  const session = sessions.get(sessionId);
  if (!session) return;
  clearTimeout(session.timer);
  send(session.offer, { type: 'sessionClosed', sessionId });
  if (session.answer) {
    send(session.answer, { type: 'sessionClosed', sessionId });
  }
  sessions.delete(sessionId);
  console.log(`[SESSION] Closed: ${sessionId}`);
}

// ── Heartbeat (detect dead connections) ──────────────────────────────────────
const heartbeat = setInterval(() => {
  wss.clients.forEach((ws) => {
    if (!ws.isAlive) {
      console.log(`[HEARTBEAT] Terminating dead client: ${ws.id}`);
      ws.terminate();
      return;
    }
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

wss.on('close', () => clearInterval(heartbeat));

// ── Stats (every 5 min) ───────────────────────────────────────────────────────
setInterval(() => {
  console.log(
    `[STATS] clients=${wss.clients.size} sessions=${sessions.size} devices=${devices.size}`
  );
}, 5 * 60 * 1000);
