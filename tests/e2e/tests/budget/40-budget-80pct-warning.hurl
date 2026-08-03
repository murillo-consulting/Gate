# BVA: at 80% budget usage, Gate should warn but still serve
# Pre-condition: budget is pre-seeded to 80% via gate spend injection (manual step)
# This test documents the expected behavior — header x-gate-budget-warning
POST http://{{host}}/v1/chat/completions
Authorization: Bearer {{jwt_default}}
Content-Type: application/json
file,fixtures/chat-simple.json;
HTTP 200
[Asserts]
jsonpath "$.choices" exists
jsonpath "$.usage" exists
# When close to budget limit, a warning header may be present
