require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const fs      = require('fs');
const path    = require('path');
const Anthropic = require('@anthropic-ai/sdk');

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

// ─── In-memory conversation store (keyed by sessionId) ───────────────────────
// Each session: { history: [{role, content}], state: {} }
const sessions = {};

function getSession(id) {
  if (!sessions[id]) {
    sessions[id] = { history: [], state: {} };
  }
  return sessions[id];
}

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ─── POST /chat ───────────────────────────────────────────────────────────────
app.post('/chat', async (req, res) => {
  const { sessionId = 'default', message } = req.body;

  if (!message) {
    return res.status(400).json({ error: 'message is required' });
  }

  const session = getSession(sessionId);
  session.history.push({ role: 'user', content: message });

  const startMs = Date.now();

  try {
    const response = await client.messages.create({
      model: MODEL,
      max_tokens: 2048,
      system: SYSTEM_PROMPT,
      messages: session.history,
    });

    const elapsedMs = Date.now() - startMs;
    const { input_tokens, output_tokens } = response.usage;
    const pricing    = PRICING[MODEL] ?? { input: 0, output: 0 };
    const totalCost  = ((input_tokens / 1e6) * pricing.input) +
                       ((output_tokens / 1e6) * pricing.output);

    // ── Observability ──
    console.log(`[${new Date().toISOString()}] session=${sessionId}`);
    console.log(`  model=${MODEL}  time=${elapsedMs}ms`);
    console.log(`  tokens in=${input_tokens} out=${output_tokens}`);
    console.log(`  cost=$${totalCost.toFixed(6)}`);

    const rawText = response.content.find(b => b.type === 'text')?.text ?? '{}';

    // ── Parse structured response ──
    let parsed;
    try {
      // Strip markdown code fences if present
      const cleaned = rawText.replace(/^```json\n?/, '').replace(/\n?```$/, '').trim();
      parsed = JSON.parse(cleaned);
    } catch {
      // Fallback: treat entire text as message, no state update
      parsed = { message: rawText, state: session.state };
    }

    // Persist latest state
    if (parsed.state) session.state = parsed.state;

    // Append assistant reply to history (store raw text for context continuity)
    session.history.push({ role: 'assistant', content: rawText });

    res.json({
      message:   parsed.message ?? '',
      state:     session.state,
      meta: {
        model:        MODEL,
        responseMs:   elapsedMs,
        inputTokens:  input_tokens,
        outputTokens: output_tokens,
        costUsd:      totalCost,
      },
    });

  } catch (err) {
    console.error('Anthropic error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /session/:id — fetch current state ───────────────────────────────────
app.get('/session/:id', (req, res) => {
  const session = sessions[req.params.id];
  if (!session) return res.json({ history: [], state: {} });
  res.json({ history: session.history, state: session.state });
});

// ─── DELETE /session/:id — reset ─────────────────────────────────────────────
app.delete('/session/:id', (req, res) => {
  delete sessions[req.params.id];
  res.json({ ok: true });
});

app.listen(PORT, () => {
  console.log(`Voyager server running on http://localhost:${PORT}`);
  console.log(`Model: ${MODEL}`);
});
