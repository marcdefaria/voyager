const webSearch = require('./web_search');

function getTools() {
  const tools = [];
  if (process.env.TOOL_WEB_SEARCH === 'true') tools.push(webSearch.definition);
  // future: if (process.env.TOOL_FLIGHTS === 'true') tools.push(flights.definition);
  // future: if (process.env.TOOL_CURRENCY === 'true') tools.push(currency.definition);
  return tools;
}

async function executeTool(name, input) {
  if (name === 'web_search') return webSearch.execute(input);
  throw new Error(`Unknown tool: ${name}`);
}

module.exports = { getTools, executeTool };
