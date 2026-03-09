require('dotenv').config();
const express   = require('express');
const cors      = require('cors');
const fs        = require('fs');
const path      = require('path');
const Anthropic  = require('@anthropic-ai/sdk');
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getTools, executeTool } = require('./tools');

// ─── Firebase Admin (uses ADC on Cloud Run, key file locally) ────────────────
initializeApp({ credential: applicationDefault() });
const db = getFirestore();

const app    = express();
const client = new Anthropic.default();
const PORT   = process.env.PORT || 3000;

// ─── Load system prompt ───────────────────────────────────────────────────────
const SYSTEM_PROMPT = fs.readFileSync(
  path.join(__dirname, '..', 'voyager_system_prompt.md'),
  'utf8'
);

// ─── Pricing ──────────────────────────────────────────────────────────────────
const PRICING = {
  'claude-opus-4-6':   { input: 5.00,  output: 25.00 },
  'claude-sonnet-4-6': { input: 3.00,  output: 15.00 },
  'claude-haiku-4-5':  { input: 1.00,  output: 5.00  },
};
const MODEL = process.env.MODEL || 'claude-haiku-4-5';

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
    const tools    = getTools();
    let messages   = [...history];
    let totalIn    = 0;
    let totalOut   = 0;
    let response;

    // ── Tool loop ──────────────────────────────────────────────────────────────
    do {
      response = await client.messages.create({
        model:      MODEL,
        max_tokens: 2048,
        system:     SYSTEM_PROMPT,
        messages,
        ...(tools.length > 0 && { tools }),
      });

      totalIn  += response.usage.input_tokens;
      totalOut += response.usage.output_tokens;

      if (response.stop_reason === 'tool_use') {
        const toolBlocks = response.content.filter(b => b.type === 'tool_use');

        // Append assistant turn (contains tool_use blocks)
        messages.push({ role: 'assistant', content: response.content });

        // Execute tools in parallel
        const toolResults = await Promise.all(
          toolBlocks.map(async (block) => {
            console.log(`[tool:${block.name}] query:`, block.input);
            const result = await executeTool(block.name, block.input);
            console.log(`[tool:${block.name}] result: ${result.slice(0, 120)}...`);
            return {
              type: 'tool_result',
              tool_use_id: block.id,
              content: result + '\n\n[Reminder: your response MUST be the JSON format specified in the system prompt. Put your answer inside the "message" field.]',
            };
          })
        );

        // Append tool results as a user turn
        messages.push({ role: 'user', content: toolResults });
      }
    } while (response.stop_reason === 'tool_use');
    // ── End tool loop ──────────────────────────────────────────────────────────

    const elapsedMs = Date.now() - startMs;
    const pricing   = PRICING[MODEL] ?? { input: 0, output: 0 };
    const totalCost = ((totalIn / 1e6) * pricing.input) + ((totalOut / 1e6) * pricing.output);

    console.log(`[${new Date().toISOString()}] session=${sessionId} time=${elapsedMs}ms in=${totalIn} out=${totalOut} cost=$${totalCost.toFixed(6)}`);

    const rawText = response.content.find(b => b.type === 'text')?.text ?? '{}';

    let parsed;
    try {
      const cleaned = rawText.replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
      parsed = JSON.parse(cleaned);
    } catch {
      // Claude didn't return JSON — preserve existing state, show message as-is
      const existingState = await getState(sessionId);
      parsed = { message: rawText, state: existingState };
      console.warn('[warn] Claude response was not JSON — state preserved from Firestore');
    }

    await saveMessage(sessionId, 'assistant', rawText);
    if (parsed.state) await saveState(sessionId, parsed.state);

    res.json({
      message: parsed.message ?? '',
      state:   parsed.state ?? {},
      meta: {
        model:        MODEL,
        responseMs:   elapsedMs,
        inputTokens:  totalIn,
        outputTokens: totalOut,
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
  const activeTools = getTools().map(t => t.name);
  console.log(`Tools: ${activeTools.length ? activeTools.join(', ') : 'none'}`);
});
