# How to Call Gate from Node.js

Send requests to a local Gate proxy using the official `@anthropic-ai/sdk` and `openai` Node SDKs. The proxy listens on `http://[::1]:13456` (IPv6 localhost) by default and accepts both Anthropic `/v1/messages` and OpenAI `/v1/chat/completions` traffic.

## Install

```bash
npm install @anthropic-ai/sdk openai
```

## Run the script

The recommended entry point is `gate exec`. It auto-starts the proxy, exports `ANTHROPIC_BASE_URL` and `OPENAI_BASE_URL`, and stops the server when the script exits.

```bash
gate exec -- node script.mjs
```

If Gate already runs, point the SDK at the proxy via `baseURL`. The `apiKey` field is a placeholder header — Gate authenticates with the upstream provider via OAuth or stored secrets, so any non-empty string works.

## Anthropic SDK, non-streaming

```javascript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({
  baseURL: "http://[::1]:13456",
  apiKey: "gate-local", // placeholder; Gate handles real auth
});

const message = await client.messages.create({
  model: "claude-sonnet-4-6",
  max_tokens: 256,
  messages: [{ role: "user", content: "Summarize the Rust borrow checker in one sentence." }],
});
console.log(message.content[0].text);
```

## OpenAI SDK, streaming

```javascript
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: "http://[::1]:13456/v1",
  apiKey: "gate-local",
});

const stream = await client.chat.completions.create({
  model: "gpt-5.4",
  messages: [{ role: "user", content: "Stream a haiku about caching." }],
  stream: true,
});

for await (const chunk of stream) {
  const delta = chunk.choices[0]?.delta?.content;
  if (delta) {
    process.stdout.write(delta);
  }
}
```

## See also

- [OpenAI Compatibility](../reference/openai-compatibility.md)
- [API Compatibility Reference](../reference/api-compatibility.md)
- [Python SDK guide](sdk-python.md)
