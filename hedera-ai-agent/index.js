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
  const prompt = ChatPromptTemplate.fromMessages([
    ['system', 'You are a helpful assistant'],
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

  // Example queries - you can modify this to test different functionality
  const queries = [
    "What's my balance?",
    "Get the current price of ETH/USD",
    "Show me the supported assets for price feeds",
    "Calculate how much SOL I would get for 1000 HBAR",
    "What are the current reserves in the swap pool?"
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
