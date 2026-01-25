# MCP Inspector Guide

Complete guide to using MCP Inspector for testing and debugging MCP servers.

## Installation

```bash
# Global installation
npm install -g @modelcontextprotocol/inspector

# Or use npx (no installation required)
npx @modelcontextprotocol/inspector <mcp-endpoint>
```

## Basic Usage

### Connect to MCP Server

```bash
# Local server
npx @modelcontextprotocol/inspector http://localhost:3030/mcp

# Remote server
npx @modelcontextprotocol/inspector https://my-mcp.workers.dev/mcp
```

### Inspector Interface

The Inspector provides:
- **Tools Panel**: List all available tools with schemas
- **Resources Panel**: View exposed resources
- **Prompts Panel**: See available prompt templates
- **Console**: Execute JSON-RPC calls directly
- **History**: Review past requests/responses

## Testing Workflows

### 1. Tool Discovery

In Inspector, navigate to Tools panel to see:
- Tool names
- Descriptions
- Input schemas (required/optional parameters)
- Output schemas

Verify:
- [ ] All expected tools are listed
- [ ] Descriptions are meaningful
- [ ] Required parameters are marked

### 2. Execute Tool Calls

Click on a tool to open the call interface:
1. Fill in required parameters
2. Add optional parameters as needed
3. Click "Execute"
4. Review response in Results panel

### 3. Raw JSON-RPC

Use Console for direct JSON-RPC calls:

```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "id": 1
}
```

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "getPet",
    "arguments": {
      "petId": 1
    }
  },
  "id": 2
}
```

## Common Testing Patterns

### List All Tools

```json
{"jsonrpc":"2.0","method":"tools/list","id":1}
```

Expected response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {
        "name": "getPet",
        "description": "Get a pet by ID",
        "inputSchema": {
          "type": "object",
          "properties": {
            "petId": {"type": "integer"}
          },
          "required": ["petId"]
        }
      }
    ]
  }
}
```

### Call a Tool

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "getPet",
    "arguments": {"petId": 1}
  },
  "id": 2
}
```

Expected response:
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"id\":1,\"name\":\"Fluffy\",\"status\":\"available\"}"
      }
    ]
  }
}
```

### Test Error Handling

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "getPet",
    "arguments": {"petId": 99999}
  },
  "id": 3
}
```

Expected: Error response with actionable message.

## Debugging Tips

### Connection Issues

If Inspector can't connect:
1. Verify server is running: `curl http://localhost:3030/health`
2. Check endpoint URL includes `/mcp` path
3. Ensure CORS is enabled if testing cross-origin

### Empty Tool List

If no tools appear:
1. Verify OpenAPI spec is valid
2. Check server logs for parsing errors
3. Ensure `--mcp` flag is enabled (default: true)

### Tool Call Errors

If tool calls fail:
1. Check required parameters are provided
2. Verify parameter types match schema
3. Review server logs for backend errors

## Command-Line Testing

For automated testing, use curl with jq:

```bash
# List tools
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq '.result.tools[].name'

# Call tool
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"listPets","arguments":{}},"id":2}' | jq '.result'

# Count tools
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq '.result.tools | length'
```

## Integration with CI/CD

Example GitHub Actions step:

```yaml
- name: Test MCP Server
  run: |
    # Start server in background
    hapi serve myapi --headless --port 3030 &
    sleep 5
    
    # Health check
    curl -f http://localhost:3030/health
    
    # Verify tools exist
    TOOL_COUNT=$(curl -s -X POST http://localhost:3030/mcp \
      -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq '.result.tools | length')
    
    if [ "$TOOL_COUNT" -lt 1 ]; then
      echo "No tools found!"
      exit 1
    fi
    
    echo "Found $TOOL_COUNT tools"
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Enter` | Execute current request |
| `Ctrl+L` | Clear console |
| `Ctrl+K` | Focus search |
| `Tab` | Autocomplete |

## Resources

- [MCP Inspector GitHub](https://github.com/modelcontextprotocol/inspector)
- [MCP Specification](https://spec.modelcontextprotocol.io/)
- [JSON-RPC 2.0 Spec](https://www.jsonrpc.org/specification)
