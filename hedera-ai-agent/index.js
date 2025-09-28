// index.js
const dotenv = require('dotenv');
dotenv.config();

const { ChatPromptTemplate } = require('@langchain/core/prompts');
const { AgentExecutor, createToolCallingAgent } = require('langchain/agents');
const { Client, PrivateKey } = require('@hashgraph/sdk');
const { HederaLangchainToolkit, coreQueriesPlugin } = require('hedera-agent-kit');
const HederaAgentTools = require('./agentTools');

// Choose your AI provider (install the one you want to use)
function createLLM() {
  // Option 1: OpenAI (requires OPENAI_API_KEY in .env)
  if (process.env.OPENAI_API_KEY) {
    const { ChatOpenAI } = require('@langchain/openai');
    return new ChatOpenAI({ model: 'gpt-4o-mini' });
  }

  // Option 2: Anthropic Claude (requires ANTHROPIC_API_KEY in .env)
  if (process.env.ANTHROPIC_API_KEY) {
    const { ChatAnthropic } = require('@langchain/anthropic');
    return new ChatAnthropic({ model: 'claude-3-haiku-20240307' });
  }

  // Option 3: Groq (requires GROQ_API_KEY in .env)
  if (process.env.GROQ_API_KEY) {
    const { ChatGroq } = require('@langchain/groq');
    return new ChatGroq({ model: 'llama-3.3-70b-versatile' });
  }

  // Option 4: Ollama (free, local - requires Ollama installed and running)
  try {
    const { ChatOllama } = require('@langchain/ollama');
    return new ChatOllama({
      model: 'llama3.2',
      baseUrl: 'http://localhost:11434'
    });
  } catch (e) {
    console.error('No AI provider configured. Please either:');
    console.error('1. Set OPENAI_API_KEY, ANTHROPIC_API_KEY, or GROQ_API_KEY in .env');
    console.error('2. Install and run Ollama locally (https://ollama.com)');
    process.exit(1);
  }
}

async function main() {
  // Initialize AI model
  const llm = createLLM();

  // Hedera client setup (Testnet by default)
  const client = Client.forTestnet().setOperator(
    process.env.HEDERA_ACCOUNT_ID,
    PrivateKey.fromStringECDSA(process.env.HEDERA_PRIVATE_KEY),
  );

  const hederaAgentToolkit = new HederaLangchainToolkit({
    client,
    configuration: {
      plugins: [coreQueriesPlugin] // all our core plugins here https://github.com/hedera-dev/hedera-agent-kit/tree/main/typescript/src/plugins
    },
  });

  // Initialize custom Hedera tools
  const hederaTools = new HederaAgentTools(client);
  await hederaTools.initialize();

  // Load the structured chat prompt template
  const systemPrompt = `You are COPYCAT HEDERA AI, an advanced AI trading assistant powered by Hedera Hashgraph consensus. You specialize in:

🔗 **Hedera Integration:**
- Real-time price feeds via Hedera Consensus Service
- Token tracking with HTS (Hedera Token Service) integration
- DeFi automation on Hedera network
- Fair lottery system using Hedera's consensus

🤖 **AI Services:**
- OpenAI GPT-4 powered market analysis and trading advice
- Twitter sentiment analysis via Gopher API
- Real-time web scraping with Masa AI
- Automated trading signal generation

⚡ **Core Features:**
- Price monitoring and alerts
- Token swap tracking and analysis
- Automated trading strategies
- Portfolio management and optimization
- Lottery system with provably fair randomness

🛡️ **Risk Management:**
- Conservative trading recommendations
- Stop-loss and take-profit calculations
- Portfolio diversification advice
- Market sentiment analysis

Always provide specific, actionable advice while emphasizing risk management. Use terminal/technical language when appropriate. Reference Hedera's unique consensus features when relevant.`;

  const prompt = ChatPromptTemplate.fromMessages([
    ['system', systemPrompt],
    ['placeholder', '{chat_history}'],
    ['human', '{input}'],
    ['placeholder', '{agent_scratchpad}'],
  ]);

  // Fetch tools from toolkit and combine with custom tools
  const coreTools = hederaAgentToolkit.getTools();
  const customTools = hederaTools.getTools();
  const tools = [...coreTools, ...customTools];

  // Create the underlying agent
  const agent = createToolCallingAgent({
    llm,
    tools,
    prompt,
  });

  // Wrap everything in an executor that will maintain memory
  const agentExecutor = new AgentExecutor({
    agent,
    tools,
  });

  // Example queries showcasing integrated services
  const queries = [
    "What's my HBAR balance?",
    "Get current price and generate trading signal for HBAR/USD",
    "Analyze Twitter sentiment for HBAR",
    "Ask AI assistant: What's the best strategy for DeFi on Hedera?",
    "Start automation monitoring for ETH, BTC, and HBAR",
    "Check lottery status and start a new round",
    "Track token 0x4675c7e5baafbffbca748158becba61ef3b0a263 and wallet 0xc8e042333e09666a627e913b0c14053d0ffef17e",
    "Scrape market data for HBAR from coindesk",
    "Analyze my trading history for the last 10 signals",
    "Calculate swap: 1000 HBAR to SOL"
  ];

  console.log('Available queries:');
  queries.forEach((query, index) => {
    console.log(`${index + 1}. ${query}`);
  });

  // Run the first query as default
  console.log('\nRunning default query...');
  const response = await agentExecutor.invoke({ input: queries[0] });
  console.log('Response:', response.output);
}

main().catch(console.error);
