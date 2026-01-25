# MCP Server Evaluation Criteria

Comprehensive criteria for evaluating MCP server quality, reliability, and usability.

## Scoring Overview

| Category | Weight | Description |
|----------|--------|-------------|
| Tool Discovery | 20% | Completeness and correctness of tool exposure |
| Basic Functionality | 30% | Valid inputs produce correct outputs |
| Error Handling | 20% | Graceful handling of invalid inputs |
| Question Accuracy | 20% | Real-world queries answered correctly |
| Performance | 10% | Response times within acceptable limits |

**Pass Threshold**: 80% overall score

## Category 1: Tool Discovery (20%)

### Criteria

| Item | Points | Description |
|------|--------|-------------|
| All operations exposed | 5 | Every OpenAPI operation appears as a tool |
| Correct naming | 3 | Names follow `verbNoun` convention |
| Accurate descriptions | 4 | Descriptions explain what tool does |
| Complete schemas | 4 | All parameters documented with types |
| Required/optional marked | 4 | Required params clearly indicated |

### Scoring Guide

- **5/5 Operations**: All OpenAPI paths/methods → tools
- **3/3 Naming**: Consistent `camelCase`, descriptive names
- **4/4 Descriptions**: Clear, actionable, non-empty
- **4/4 Schemas**: Types, descriptions, constraints present
- **4/4 Required**: `required` array accurate, matches OpenAPI

### Example Check

```bash
# Get tool count
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq '.result.tools | length'

# Verify tool has description
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq '.result.tools[] | select(.description == "") | .name'
```

## Category 2: Basic Functionality (30%)

### Criteria

| Item | Points | Description |
|------|--------|-------------|
| GET operations work | 8 | Read operations return data |
| POST operations work | 8 | Create operations succeed |
| PUT/PATCH work | 7 | Update operations succeed |
| DELETE works | 7 | Delete operations succeed |

### Testing Protocol

For each operation type:
1. Execute with valid parameters
2. Verify response contains expected data
3. Verify response format matches schema
4. Check for no unexpected errors

### Example Tests

```bash
# Test GET (list)
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"listPets","arguments":{}},"id":1}' | jq '.result.content[0].text'

# Test GET (single item)
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"getPet","arguments":{"petId":1}},"id":2}' | jq '.result'

# Test POST (create)
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"addPet","arguments":{"name":"TestPet","status":"available"}},"id":3}' | jq '.result'
```

## Category 3: Error Handling (20%)

### Criteria

| Item | Points | Description |
|------|--------|-------------|
| Missing required params | 5 | Clear error identifying missing param |
| Invalid param types | 5 | Type mismatch errors are clear |
| Not found errors | 5 | 404s translated to readable errors |
| Auth errors | 5 | 401/403 translated appropriately |

### Testing Protocol

1. Call tool with missing required parameter
2. Call tool with wrong type (string instead of number)
3. Call tool with non-existent ID
4. Call tool without required auth (if applicable)

### Example Tests

```bash
# Missing required param
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"getPet","arguments":{}},"id":1}' | jq '.error // .result'

# Invalid ID
curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"getPet","arguments":{"petId":99999999}},"id":2}' | jq '.error // .result'
```

### Error Quality Checklist

- [ ] Error message identifies the problem
- [ ] Error message suggests how to fix
- [ ] No stack traces exposed to users
- [ ] HTTP status codes preserved in context

## Category 4: Question Accuracy (20%)

### Criteria

| Item | Points | Description |
|------|--------|-------------|
| Simple queries | 5 | Single-tool questions answered correctly |
| Complex queries | 5 | Multi-step workflows succeed |
| Edge cases | 5 | Empty results handled gracefully |
| Negative tests | 5 | Invalid queries fail appropriately |

### Question Types to Test

1. **Simple Query** (5 pts): "List all available pets"
2. **Filtered Query** (5 pts): "Find pets with status 'sold'"
3. **Detail Query** (5 pts): "Get details of pet ID 1"
4. **Aggregate** (5 pts): "How many pets are available?"

### Scoring Guide

- **Correct**: Answer matches expected result (full points)
- **Partial**: Answer is incomplete but not wrong (half points)
- **Incorrect**: Wrong answer or error (no points)

## Category 5: Performance (10%)

### Criteria

| Item | Points | Description |
|------|--------|-------------|
| Health check < 200ms | 2 | Fast health responses |
| Tool list < 500ms | 3 | Metadata retrieval is quick |
| Simple calls < 2s | 3 | Basic operations complete quickly |
| Complex calls < 5s | 2 | Multi-step operations acceptable |

### Measurement

```bash
# Health check timing
time curl -s http://localhost:3030/health

# Tool list timing
time curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'

# Tool call timing
time curl -s -X POST http://localhost:3030/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"listPets","arguments":{}},"id":2}'
```

## Evaluation Report Template

```markdown
# MCP Server Evaluation Report

**Server**: [name/URL]
**Date**: [date]
**Evaluator**: [name]

## Summary

| Category | Score | Max | Percentage |
|----------|-------|-----|------------|
| Tool Discovery | | 20 | |
| Basic Functionality | | 30 | |
| Error Handling | | 20 | |
| Question Accuracy | | 20 | |
| Performance | | 10 | |
| **Total** | | **100** | |

**Result**: PASS / FAIL (threshold: 80%)

## Detailed Findings

### Tool Discovery
- Tools found: [count]
- Missing operations: [list]
- Naming issues: [list]

### Basic Functionality
- Working operations: [list]
- Failing operations: [list]

### Error Handling
- Error quality: [assessment]
- Issues: [list]

### Question Accuracy
- Questions tested: [count]
- Correct: [count]
- Partial: [count]
- Incorrect: [count]

### Performance
- Average response time: [ms]
- Slowest operation: [name, time]

## Recommendations

1. [recommendation 1]
2. [recommendation 2]
```

## Quick Pass/Fail Criteria

For rapid assessment, these are **must-pass** criteria:

- [ ] Health endpoint returns 200
- [ ] At least 1 tool is exposed
- [ ] At least 1 tool call succeeds
- [ ] Error responses include message (not empty)
- [ ] Response time < 10s for any operation
