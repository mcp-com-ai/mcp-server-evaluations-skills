#!/usr/bin/env bash
#
# MCP Server Basic Evaluation Script
# Usage: ./run-basic-tests.sh [MCP_ENDPOINT]
# Example: ./run-basic-tests.sh http://localhost:3030
#

set -euo pipefail

# Configuration
MCP_ENDPOINT="${1:-http://localhost:3030}"
MCP_PATH="${MCP_ENDPOINT}/mcp"
HEALTH_PATH="${MCP_ENDPOINT}/health"
PING_PATH="${MCP_PATH}/ping"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
log_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAILED++))
}

log_warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    ((WARNINGS++))
}

log_info() {
    echo -e "ℹ INFO: $1"
}

# Check if jq is available
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed."
        echo "Install with: apt install jq / brew install jq"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is required but not installed."
        exit 1
    fi
}

# Test functions
test_health() {
    log_info "Testing health endpoint: ${HEALTH_PATH}"
    
    local response
    local http_code
    
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "${HEALTH_PATH}" 2>/dev/null || echo "000")
    
    if [ "$http_code" = "200" ]; then
        log_pass "Health endpoint returns 200"
    else
        log_fail "Health endpoint returns ${http_code} (expected 200)"
    fi
}

test_ping() {
    log_info "Testing MCP ping (POST): ${PING_PATH}"

    local response
    local ping_id
    ping_id=$((RANDOM + 1000))

    response=$(curl -s -X POST "${PING_PATH}" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"${ping_id}\",\"method\":\"ping\"}" 2>/dev/null)

    # Check for expected JSON-RPC response
    if echo "$response" | jq -e ".jsonrpc == \"2.0\" and .id == \"${ping_id}\" and (.result == {} or .result == null)" > /dev/null 2>&1; then
        log_pass "MCP ping returns valid JSON-RPC response"
    else
        log_fail "MCP ping failed - response: ${response}"
    fi
}

test_tools_list() {
    log_info "Testing tools/list endpoint"
    
    local response
    local tool_count
    
    response=$(curl -s -X POST "${MCP_PATH}" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' 2>/dev/null)
    
    if echo "$response" | jq -e '.result.tools' > /dev/null 2>&1; then
        tool_count=$(echo "$response" | jq '.result.tools | length')
        log_pass "Tools list returns ${tool_count} tools"
        
        if [ "$tool_count" -eq 0 ]; then
            log_warn "No tools exposed - verify OpenAPI spec is loaded"
        fi
    else
        log_fail "Tools list failed - response: ${response}"
    fi
}

test_tool_schemas() {
    log_info "Validating tool schemas"
    
    local response
    local invalid_count
    
    response=$(curl -s -X POST "${MCP_PATH}" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' 2>/dev/null)
    
    # Check for tools without descriptions
    invalid_count=$(echo "$response" | jq '[.result.tools[] | select(.description == "" or .description == null)] | length')
    
    if [ "$invalid_count" -eq 0 ]; then
        log_pass "All tools have descriptions"
    else
        log_warn "${invalid_count} tools missing descriptions"
    fi
    
    # Check for tools without input schemas
    invalid_count=$(echo "$response" | jq '[.result.tools[] | select(.inputSchema == null)] | length')
    
    if [ "$invalid_count" -eq 0 ]; then
        log_pass "All tools have input schemas"
    else
        log_warn "${invalid_count} tools missing input schemas"
    fi
}

test_sample_tool_call() {
    log_info "Testing sample tool call"
    
    local response
    local first_tool
    
    # Get first tool name
    response=$(curl -s -X POST "${MCP_PATH}" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' 2>/dev/null)
    
    first_tool=$(echo "$response" | jq -r '.result.tools[0].name // empty')
    
    if [ -z "$first_tool" ]; then
        log_warn "No tools available to test"
        return
    fi
    
    log_info "Calling tool: ${first_tool}"
    
    # Try calling with empty arguments (may fail, that's OK)
    response=$(curl -s -X POST "${MCP_PATH}" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"${first_tool}\",\"arguments\":{}},\"id\":2}" 2>/dev/null)
    
    if echo "$response" | jq -e '.result' > /dev/null 2>&1; then
        log_pass "Tool call succeeded"
    elif echo "$response" | jq -e '.error' > /dev/null 2>&1; then
        local error_msg
        error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"')
        log_info "Tool call returned error (expected for tools requiring params): ${error_msg}"
        
        # Check if error message is actionable
        if [ ${#error_msg} -gt 10 ]; then
            log_pass "Error message is descriptive"
        else
            log_warn "Error message may not be helpful: ${error_msg}"
        fi
    else
        log_fail "Unexpected response: ${response}"
    fi
}

test_response_time() {
    log_info "Testing response times"
    
    local start_time
    local end_time
    local duration
    
    # Health endpoint timing
    start_time=$(date +%s%3N)
    curl -s "${HEALTH_PATH}" > /dev/null 2>&1
    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    
    if [ "$duration" -lt 500 ]; then
        log_pass "Health response time: ${duration}ms"
    else
        log_warn "Health response time slow: ${duration}ms (expected <500ms)"
    fi
    
    # Tools list timing
    start_time=$(date +%s%3N)
    curl -s -X POST "${MCP_PATH}" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' > /dev/null 2>&1
    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    
    if [ "$duration" -lt 1000 ]; then
        log_pass "Tools list response time: ${duration}ms"
    else
        log_warn "Tools list response time slow: ${duration}ms (expected <1000ms)"
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "MCP Server Basic Evaluation"
    echo "Endpoint: ${MCP_ENDPOINT}"
    echo "=========================================="
    echo ""
    
    check_dependencies
    
    test_health
    test_ping
    test_tools_list
    test_tool_schemas
    test_sample_tool_call
    test_response_time
    
    echo ""
    echo "=========================================="
    echo "Summary"
    echo "=========================================="
    echo -e "Passed:   ${GREEN}${PASSED}${NC}"
    echo -e "Failed:   ${RED}${FAILED}${NC}"
    echo -e "Warnings: ${YELLOW}${WARNINGS}${NC}"
    echo ""
    
    if [ "$FAILED" -eq 0 ]; then
        echo -e "${GREEN}✓ All basic tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

main "$@"
