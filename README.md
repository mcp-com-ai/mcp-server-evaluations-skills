<!--
MCP.com.ai — Skill README
Aligned with SKILL.md for mcp-server-evaluations
-->

<p align="center">
  <img src="https://img.shields.io/badge/MCP-Model%20Context%20Protocol-1193b0?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Quality%20Evals-Server%20Reliability-da7756?style=for-the-badge" />
</p>

<h1 align="center">MCP Server Evaluations Skill</h1>

<p align="center">
  <b>API-First for AI.</b><br/>
  Systematically evaluate MCP servers for correctness, error handling, and response quality using <b>curl + jq</b> (and optional Bun/Node).
</p>

<p align="center">
  <a href="https://mcp.com.ai"><b>Website</b></a>
  ·
  <a href="https://docs.mcp.com.ai"><b>Docs</b></a>
  ·
  <a href="https://registry.modelcontextprotocol.io/?q=ai.com.mcp"><b>MCP Servers</b></a>  
  ·
  <a href="https://run.mcp.com.ai"><b>Run MCP</b></a>
  ·
  <a href="https://hapi.mcp.com.ai"><b>CLI Tool</b></a>
</p>

---

## 🪝 Why this exists

MCP quality is measurable. This skill provides a repeatable evaluation workflow to ensure:
- **Tools are discoverable** and correctly described
- **Tool calls work** with valid inputs
- **Errors are actionable** for invalid inputs
- **Answers are reliable** under realistic questions
- **Performance stays acceptable**

---

## ⚡ What you’ll find here

### ✅ Skill-aligned workflow
- Environment verification (MCP server health + ping)
- Tool discovery and completeness checks
- Functional testing per tool
- Question-based evaluation
- Scoring rubric and pass threshold

### ✅ Minimal dependencies
- `curl` and `jq` required
- Optional: `bun` or `node` for local automation

### ✅ Reference guides
- Inspector usage
- Evaluation criteria
- Question templates

---

## 🚀 Quickstart (Skill Summary)

### Requirements
- `curl`
- `jq`
- Optional: `bun` or `node` (v22+)

### 1) Verify MCP server health
```bash
curl -s http://localhost:3030/health
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"ping"}'
```

### 2) List available tools
```bash
curl -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

### 3) Call a tool (basic function test)
```bash
curl -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {"name": "<tool_name>", "arguments": {<valid_arguments>}},
    "id": 2
  }'
```

### 4) Trigger an error (quality check)
```bash
curl -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {"name": "<tool_name>", "arguments": {}},
    "id": 3
  }'
```

---

## ✅ Evaluation Checklist (Fast Pass)

```bash
# Health check
curl -s http://localhost:3030/health | grep -q "" && echo "✓ Health OK" || echo "✗ Health FAILED"

# MCP ping
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"ping"}' | jq -e '.jsonrpc == "2.0" and .result' > /dev/null && echo "✓ Ping OK" || echo "✗ Ping FAILED"

# Tools list
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq '.result.tools | length' | xargs -I {} echo "✓ {} tools discovered"
```

---

## 📊 Scoring rubric

| Category | Weight | Criteria |
|----------|--------|----------|
| Tool Discovery | 20% | All operations exposed, proper naming |
| Basic Functionality | 30% | Valid inputs return correct responses |
| Error Handling | 20% | Actionable errors, missing args reported |
| Question Accuracy | 20% | Test questions answered correctly |
| Performance | 10% | Responses < 5s for standard ops |

**Pass threshold**: 80% overall score

---

## 🧪 Question templates

Use these to generate test prompts:
1. List/Query: "Show me all [resources] that match [criteria]"
2. Get Details: "What are the details of [resource] with ID [id]?"
3. Create: "Create a new [resource] with [properties]"
4. Update: "Update [resource] [id] to change [field] to [value]"
5. Delete: "Remove [resource] with ID [id]"
6. Aggregate: "How many [resources] exist with [status]?"
7. Search: "Find [resources] where [field] contains [term]"
8. Workflow: "Create a [resource], then update it, then list all"

---

## 📚 References

- [Inspector guide](references/mcp-inspector-guide.md)
- [Evaluation criteria](references/evaluation-criteria.md)
- [Question templates](references/question-templates.md)

---

<p align="center">
  <img src="https://img.shields.io/badge/La%20Rebelion%20Labs-Building%20API--First%20for%20AI-0d1117?style=for-the-badge&labelColor=1193b0&color=da7756" />
</p>
