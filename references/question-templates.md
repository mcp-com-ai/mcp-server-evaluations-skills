# Test Question Templates

Templates and examples for generating effective test questions for MCP server evaluation.

## Question Generation Principles

1. **Cover all tools**: At least one question per exposed tool
2. **Vary complexity**: Mix simple and multi-step questions
3. **Include edge cases**: Empty results, large datasets, special characters
4. **Test errors**: Invalid inputs, missing resources
5. **Be realistic**: Questions a real user would ask

## Template Categories

### 1. List/Query Questions

**Pattern**: "Show me all [resources] that match [criteria]"

**Examples**:
- "List all available pets"
- "Show me orders from the last week"
- "Find all users with admin role"
- "Get all products in the electronics category"

**Expected behavior**:
- Returns array of matching items
- Empty array if no matches (not error)
- Pagination if many results

### 2. Get Details Questions

**Pattern**: "What are the details of [resource] with ID [id]?"

**Examples**:
- "Show me the details of pet with ID 123"
- "What is order 456 about?"
- "Get user profile for user_abc"
- "Display product information for SKU-789"

**Expected behavior**:
- Returns complete resource object
- 404-style error if not found
- All fields from schema present

### 3. Create Questions

**Pattern**: "Create a new [resource] with [properties]"

**Examples**:
- "Create a new pet named 'Fluffy' with status available"
- "Add a new order for 3 units of product X"
- "Register a new user with email test@example.com"
- "Create a todo item: 'Buy groceries'"

**Expected behavior**:
- Returns created resource with ID
- Validation errors for missing required fields
- Confirmation of creation

### 4. Update Questions

**Pattern**: "Update [resource] [id] to change [field] to [value]"

**Examples**:
- "Change pet 123's status to 'sold'"
- "Update order 456 quantity to 5"
- "Set user xyz's role to 'moderator'"
- "Mark todo 789 as completed"

**Expected behavior**:
- Returns updated resource
- 404 if resource doesn't exist
- Validation for invalid values

### 5. Delete Questions

**Pattern**: "Remove [resource] with ID [id]"

**Examples**:
- "Delete pet 123"
- "Cancel order 456"
- "Remove user xyz from the system"
- "Delete my todo item 789"

**Expected behavior**:
- Confirmation of deletion
- 404 if already deleted/doesn't exist
- May return deleted resource or just success

### 6. Aggregate Questions

**Pattern**: "How many [resources] exist with [condition]?"

**Examples**:
- "How many pets are available?"
- "What's the total number of pending orders?"
- "Count users registered this month"
- "How many products are out of stock?"

**Expected behavior**:
- Returns numeric count
- May require multiple tool calls
- Zero is valid result

### 7. Search Questions

**Pattern**: "Find [resources] where [field] contains [term]"

**Examples**:
- "Find pets with 'golden' in their name"
- "Search for orders containing product X"
- "Find users whose email ends with @example.com"
- "Look for products matching 'wireless'"

**Expected behavior**:
- Returns filtered array
- Empty array if no matches
- Case sensitivity handled appropriately

### 8. Workflow Questions

**Pattern**: Multi-step operations

**Examples**:
- "Create a new pet, then show me its details"
- "List all available pets and tell me how many there are"
- "Find pet 123, update its status to sold, then confirm the change"
- "Create an order, add 3 items to it, then calculate the total"

**Expected behavior**:
- Multiple tool calls in sequence
- State maintained between calls
- Final result reflects all steps

## Edge Case Questions

### Empty Results

- "List pets with status 'mythical'" → empty array
- "Find orders from year 1900" → empty array
- "Search for product 'xyznonexistent'" → empty array

### Large Datasets

- "List all orders ever made" → pagination or truncation
- "Get complete user activity log" → streaming or limits

### Special Characters

- "Create pet named 'O'Malley'" → apostrophe handling
- "Search for 'foo & bar'" → ampersand handling
- "Find user 'test+tag@example.com'" → plus sign handling

### Boundary Values

- "Get pet with ID 0" → valid or error?
- "Get pet with ID -1" → should error
- "Create pet with 1000-character name" → validation

### Authentication Edge Cases

- "Access admin-only resource as regular user" → 403
- "Access resource with expired token" → 401
- "Access public resource without auth" → should work

## Question Bank by API Type

### Pet Store API

```
1. List all available pets
2. Show details of pet with ID 1
3. Find pets with status 'pending'
4. Create a new cat named 'Whiskers'
5. Update pet 1 status to 'sold'
6. Delete pet 999
7. How many pets are available?
8. Find pets with 'dog' in their category
9. Create a pet, then immediately fetch its details
10. List pets, pick the first one, update its name
```

### Todo API

```
1. Show all my todos
2. Get todo item 123
3. Find incomplete todos
4. Create todo: 'Review MCP server'
5. Mark todo 456 as complete
6. Delete todo 789
7. Count incomplete todos
8. Find todos containing 'meeting'
9. Create 3 todos, then list all
10. Complete all todos created today
```

### User Management API

```
1. List all users
2. Get user profile for ID abc123
3. Find users with admin role
4. Create new user: email test@test.com
5. Update user's display name
6. Deactivate user xyz
7. Count active users
8. Search users by email domain
9. Create user, assign role, verify
10. List users, find newest, get full profile
```

## Verification Checklist

For each question, verify:

- [ ] **Parsed correctly**: Question understood by LLM
- [ ] **Right tool selected**: Correct tool(s) identified
- [ ] **Parameters extracted**: Values correctly extracted
- [ ] **Tool executed**: No MCP transport errors
- [ ] **Response valid**: Matches expected schema
- [ ] **Answer accurate**: Response is correct
- [ ] **Answer complete**: All relevant info included
- [ ] **Error handled**: If error, message is helpful

## Generating Questions Programmatically

Given an OpenAPI spec, generate questions:

```javascript
function generateQuestions(openApiSpec) {
  const questions = [];
  
  for (const [path, methods] of Object.entries(openApiSpec.paths)) {
    for (const [method, operation] of Object.entries(methods)) {
      const resource = extractResource(path);
      
      if (method === 'get' && path.includes('{')) {
        questions.push(`Get details of ${resource} with ID [example_id]`);
      } else if (method === 'get') {
        questions.push(`List all ${resource}`);
      } else if (method === 'post') {
        questions.push(`Create a new ${resource} with [example_fields]`);
      } else if (method === 'put' || method === 'patch') {
        questions.push(`Update ${resource} [example_id] to change [field]`);
      } else if (method === 'delete') {
        questions.push(`Delete ${resource} [example_id]`);
      }
    }
  }
  
  return questions;
}
```

## Minimum Question Set

For any API evaluation, test at minimum:

1. **Health**: Is the server responding?
2. **Discovery**: Can we list tools?
3. **Read**: Can we fetch data?
4. **Write**: Can we create/update?
5. **Error**: Do errors make sense?
6. **Edge**: What about empty/invalid?
7. **Workflow**: Do multi-step operations work?
