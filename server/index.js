require('dotenv').config();
const express   = require('express');
const cors      = require('cors');
const fs        = require('fs');
const path      = require('path');
const Anthropic  = require('@anthropic-ai/sdk');
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// ─── Firebase Admin (uses ADC on Cloud Run, key file locally) ────────────────
initializeApp({ credential: applicationDefault() });
const db = getFirestore();

const app    = express();
const client = new Anthropic.default();
const PORT   = process.env.PORT || 3000;

// ─── Load system prompt ───────────────────────────────────────────────────────
const SYSTEM_PROMPT = fs.readFileSync(
  path.join(__dirname, '../voyager_system_prompt.md'),
  'utf8'
);

// ─── Pricing ──────────────────────────────────────────────────────────────────
const PRICING = {
  'claude-opus-4-6':   { input: 5.00,  output: 25.00 },
  'claude-sonnet-4-6': { input: 3.00,  output: 15.00 },
  'claude-haiku-4-5':  { input: 1.00,  output: 5.00  },
};
const MODEL = process.env.MODEL || 'claude-opus-4-6';

// ─── Firestore helpers ────────────────────────────────────────────────────────

async function getHistory(sessionId) {
  const snap = await db
    .collection('sessions').doc(sessionId)
    .collection('messages')
    .orderBy('timestamp')
    .get();
  return snap.docs.map(d => ({ role: d.data().role, content: d.data().content }));
}

async function getState(sessionId) {
  const doc = await db.collection('sessions').doc(sessionId).get();
  return doc.exists ? (doc.data().state ?? {}) : {};
}

async function saveMessage(sessionId, role, content) {
  await db
    .collection('sessions').doc(sessionId)
    .collection('messages')
    .add({ role, content, timestamp: FieldValue.serverTimestamp() });
}

async function saveState(sessionId, state) {
  await db.collection('sessions').doc(sessionId).set(
    { state, updatedAt: FieldValue.serverTimestamp() },
    { merge: true }
  );
}

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ─── POST /chat ───────────────────────────────────────────────────────────────
app.post('/chat', async (req, res) => {
  const { sessionId = 'default', message } = req.body;
  if (!message) return res.status(400).json({ error: 'message is required' });

  await saveMessage(sessionId, 'user', message);

  const history = await getHistory(sessionId);
  const startMs = Date.now();

  try {
    const response = await client.messages.create({
      model: MODEL,
      max_tokens: 2048,
      system: SYSTEM_PROMPT,
      messages: history,
    });

    const elapsedMs = Date.now() - startMs;
    const { input_tokens, output_tokens } = response.usage;
    const pricing   = PRICING[MODEL] ?? { input: 0, output: 0 };
    const totalCost = ((input_tokens / 1e6) * pricing.input) +
                      ((output_tokens / 1e6) * pricing.output);

    console.log(`[${new Date().toISOString()}] session=${sessionId} time=${elapsedMs}ms in=${input_tokens} out=${output_tokens} cost=$${totalCost.toFixed(6)}`);

    const rawText = response.content.find(b => b.type === 'text')?.text ?? '{}';

    let parsed;
    try {
      const cleaned = rawText.replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
      parsed = JSON.parse(cleaned);
    } catch {
      parsed = { message: rawText, state: await getState(sessionId) };
    }

    await saveMessage(sessionId, 'assistant', rawText);
    if (parsed.state) await saveState(sessionId, parsed.state);

    res.json({
      message: parsed.message ?? '',
      state:   parsed.state ?? {},
      meta: {
        model:        MODEL,
        responseMs:   elapsedMs,
        inputTokens:  input_tokens,
        outputTokens: output_tokens,
        costUsd:      totalCost,
      },
    });

  } catch (err) {
    console.error('Error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /session/:id ─────────────────────────────────────────────────────────
app.get('/session/:id', async (req, res) => {
  const [history, state] = await Promise.all([
    getHistory(req.params.id),
    getState(req.params.id),
  ]);
  res.json({ history, state });
});

// ─── DELETE /session/:id ──────────────────────────────────────────────────────
app.delete('/session/:id', async (req, res) => {
  await db.collection('sessions').doc(req.params.id).delete();
  res.json({ ok: true });
});

app.listen(PORT, () => {
  console.log(`Voyager server running on http://localhost:${PORT}`);
  console.log(`Model: ${MODEL}`);
});
