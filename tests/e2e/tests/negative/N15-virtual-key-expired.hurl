# Expired virtual key format rejected in JWT auth mode.
# An expired gate_ key passed via X-Api-Key must also be rejected
# when the server is configured for JWT authentication.
POST http://{{host}}/v1/chat/completions
X-Api-Key: gate_expired000000000000000000000
Content-Type: application/json
file,fixtures/chat-simple.json;
HTTP 401
