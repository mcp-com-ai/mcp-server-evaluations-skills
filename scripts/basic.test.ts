#!/usr/bin/env -S node --experimental-strip-types
/**
 * MCP Server Basic Evaluation Test
 * 
 * Usage: 
 *   bun run basic.test.ts [MCP_ENDPOINT]
 *   node basic.test.ts [MCP_ENDPOINT]
 * 
 * Example: 
 *   bun run basic.test.ts http://localhost:3030
 * 
 * Requirements:
 *   - Bun, or Node.js v22.18.0+
 */

// Color codes
const colors = {
  red: '\x1b[0;31m',
  green: '\x1b[0;32m',
  yellow: '\x1b[1;33m',
  reset: '\x1b[0m',
};

// Test counters
let passed = 0;
let failed = 0;
let warnings = 0;

// Configuration
const MCP_ENDPOINT = process.argv[2] || 'http://localhost:3030';
const HEALTH_PATH = `${MCP_ENDPOINT}/health`;
const MCP_PATH = `${MCP_ENDPOINT}/mcp`;
const PING_PATH = `${MCP_PATH}`;

// Helper functions
function logPass(message: string): void {
  console.log(`${colors.green}✓ PASS${colors.reset}: ${message}`);
  passed++;
}

function logFail(message: string): void {
  console.log(`${colors.red}✗ FAIL${colors.reset}: ${message}`);
  failed++;
}

function logWarn(message: string): void {
  console.log(`${colors.yellow}⚠ WARN${colors.reset}: ${message}`);
  warnings++;
}

function logInfo(message: string): void {
  console.log(`ℹ INFO: ${message}`);
}

// Test functions
async function testHealth(): Promise<void> {
  logInfo(`Testing health endpoint: ${HEALTH_PATH}`);

  try {
    const response = await fetch(HEALTH_PATH);
    const httpCode = response.status;

    if (httpCode === 200) {
      logPass('Health endpoint returns 200');
    } else {
      logFail(`Health endpoint returns ${httpCode} (expected 200)`);
    }
  } catch (error) {
    logFail(`Health endpoint error: ${error}`);
  }
}

async function testPing(): Promise<void> {
  logInfo(`Testing MCP ping (POST): ${PING_PATH}`);

  try {
    const pingId = Math.floor(Math.random() * 1000) + 1000;
    const response = await fetch(PING_PATH, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        jsonrpc: '2.0',
        id: String(pingId),
        method: 'ping',
      }),
    });

    const data = await response.json();

    // Check for expected JSON-RPC response
    if (
      data.jsonrpc === '2.0' &&
      data.id === String(pingId) &&
      (data.result === null || typeof data.result === 'object')
    ) {
      logPass('MCP ping returns valid JSON-RPC response');
    } else {
      logFail(`MCP ping failed - response: ${JSON.stringify(data)}`);
    }
  } catch (error) {
    logFail(`MCP ping error: ${error}`);
  }
}

async function testToolsList(): Promise<{ tools: any[] }> {
  logInfo('Testing tools/list endpoint');

  try {
    const response = await fetch(MCP_PATH, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        jsonrpc: '2.0',
        method: 'tools/list',
        id: 1,
      }),
    });

    const data = await response.json();

    if (data.result && Array.isArray(data.result.tools)) {
      const toolCount = data.result.tools.length;
      logPass(`Tools list returns ${toolCount} tools`);

      if (toolCount === 0) {
        logWarn('No tools exposed - verify OpenAPI spec is loaded');
      }

      return { tools: data.result.tools };
    } else {
      logFail(`Tools list failed - response: ${JSON.stringify(data)}`);
      return { tools: [] };
    }
  } catch (error) {
    logFail(`Tools list error: ${error}`);
    return { tools: [] };
  }
}

async function testToolSchemas(tools: any[]): Promise<void> {
  logInfo('Validating tool schemas');

  // Check for tools without descriptions
  const missingDescriptions = tools.filter(
    (tool) => !tool.description || tool.description === ''
  );

  if (missingDescriptions.length === 0) {
    logPass('All tools have descriptions');
  } else {
    logWarn(`${missingDescriptions.length} tools missing descriptions`);
  }

  // Check for tools without input schemas
  const missingSchemas = tools.filter((tool) => !tool.inputSchema);

  if (missingSchemas.length === 0) {
    logPass('All tools have input schemas');
  } else {
    logWarn(`${missingSchemas.length} tools missing input schemas`);
  }
}

async function testSampleToolCall(tools: any[]): Promise<void> {
  logInfo('Testing sample tool call');

  if (tools.length === 0) {
    logWarn('No tools available to test');
    return;
  }

  const firstTool = tools[0];
  logInfo(`Calling tool: ${firstTool.name}`);

  try {
    const response = await fetch(MCP_PATH, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        jsonrpc: '2.0',
        method: 'tools/call',
        params: {
          name: firstTool.name,
          arguments: {},
        },
        id: 2,
      }),
    });

    const data = await response.json();

    if (data.result) {
      logPass('Tool call succeeded');
    } else if (data.error) {
      const errorMsg = data.error.message || 'Unknown error';
      logInfo(`Tool call returned error (expected for tools requiring params): ${errorMsg}`);

      // Check if error message is actionable
      if (errorMsg.length > 10) {
        logPass('Error message is descriptive');
      } else {
        logWarn(`Error message may not be helpful: ${errorMsg}`);
      }
    } else {
      logFail(`Unexpected response: ${JSON.stringify(data)}`);
    }
  } catch (error) {
    logFail(`Tool call error: ${error}`);
  }
}

async function testResponseTime(): Promise<void> {
  logInfo('Testing response times');

  try {
    // Health endpoint timing
    const healthStart = Date.now();
    await fetch(HEALTH_PATH);
    const healthDuration = Date.now() - healthStart;

    if (healthDuration < 500) {
      logPass(`Health response time: ${healthDuration}ms`);
    } else {
      logWarn(`Health response time slow: ${healthDuration}ms (expected <500ms)`);
    }

    // Tools list timing
    const toolsStart = Date.now();
    await fetch(MCP_PATH, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        jsonrpc: '2.0',
        method: 'tools/list',
        id: 1,
      }),
    });
    const toolsDuration = Date.now() - toolsStart;

    if (toolsDuration < 1000) {
      logPass(`Tools list response time: ${toolsDuration}ms`);
    } else {
      logWarn(`Tools list response time slow: ${toolsDuration}ms (expected <1000ms)`);
    }
  } catch (error) {
    logFail(`Response time test error: ${error}`);
  }
}

// Main execution
async function main(): Promise<void> {
  console.log('==========================================');
  console.log('MCP Server Basic Evaluation');
  console.log(`Endpoint: ${MCP_ENDPOINT}`);
  console.log('==========================================');
  console.log('');

  await testHealth();
  await testPing();
  const { tools } = await testToolsList();
  await testToolSchemas(tools);
  await testSampleToolCall(tools);
  await testResponseTime();

  console.log('');
  console.log('==========================================');
  console.log('Summary');
  console.log('==========================================');
  console.log(`Passed:   ${colors.green}${passed}${colors.reset}`);
  console.log(`Failed:   ${colors.red}${failed}${colors.reset}`);
  console.log(`Warnings: ${colors.yellow}${warnings}${colors.reset}`);
  console.log('');

  if (failed === 0) {
    console.log(`${colors.green}✓ All basic tests passed!${colors.reset}`);
    process.exit(0);
  } else {
    console.log(`${colors.red}✗ Some tests failed${colors.reset}`);
    process.exit(1);
  }
}

// Run tests
main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
