const definition = {
  name: 'web_search',
  description: `Search the web for current, real-time travel information.
Use this tool whenever the user asks about:
- Visa requirements, entry restrictions, or passport validity rules
- Travel advisories or safety warnings
- Current prices, fees, or taxes
- ETIAS, eTA, or any electronic travel authorisation
- Any information that may have changed recently
Always include nationality and destination country in the query for visa questions.`,
  input_schema: {
    type: 'object',
    properties: {
      query: {
        type: 'string',
        description: 'Specific search query. For visa questions include passport nationality, destination country, and current year.',
      },
    },
    required: ['query'],
  },
};

async function execute({ query }) {
  if (!process.env.TAVILY_API_KEY) {
    return 'Web search unavailable: TAVILY_API_KEY not configured.';
  }

  const res = await fetch('https://api.tavily.com/search', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      api_key: process.env.TAVILY_API_KEY,
      query,
      search_depth: 'basic',
      max_results: 5,
      include_answer: true,
    }),
  });

  if (!res.ok) return `Search failed (${res.status}).`;

  const data = await res.json();
  const parts = [];

  if (data.answer) parts.push(`Summary: ${data.answer}`);

  if (data.results?.length) {
    parts.push(
      data.results.slice(0, 3)
        .map(r => `[${r.title}]\n${r.content}\nSource: ${r.url}`)
        .join('\n\n')
    );
  }

  return parts.join('\n\n') || 'No results found.';
}

module.exports = { definition, execute };
