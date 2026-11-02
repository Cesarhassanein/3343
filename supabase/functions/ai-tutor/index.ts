import { corsHeaders } from '../_shared/cors.ts';

const jsonHeaders = { ...corsHeaders, 'Content-Type': 'application/json' };

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: jsonHeaders,
    });
  }

  // Supabase Edge Functions should keep JWT verification enabled. The provider key
  // is configured as a server secret and must never be shipped in the Flutter app.
  const apiKey = Deno.env.get('OPENAI_API_KEY');
  if (!apiKey) {
    return new Response(JSON.stringify({ error: 'AI provider is not configured' }), {
      status: 503,
      headers: jsonHeaders,
    });
  }

  try {
    const body = await request.json();
    const prompt = typeof body?.prompt === 'string' ? body.prompt.trim() : '';
    if (!prompt || prompt.length > 8000) {
      return new Response(JSON.stringify({ error: 'Prompt is empty or too long' }), {
        status: 400,
        headers: jsonHeaders,
      });
    }

    const upstream = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: Deno.env.get('OPENAI_MODEL') ?? 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: 'أنت مساعد تعليمي عربي لمنصة ودق. اشرح بوضوح، لا تختلق معلومات أو مصادر، واذكر عندما لا تكون متأكدًا.',
          },
          { role: 'user', content: prompt },
        ],
        temperature: 0.4,
      }),
    });

    const payload = await upstream.json();
    if (!upstream.ok) {
      // Do not expose provider response details or credentials to the client.
      return new Response(JSON.stringify({ error: 'AI provider request failed' }), {
        status: 502,
        headers: jsonHeaders,
      });
    }

    const answer = payload?.choices?.[0]?.message?.content;
    if (typeof answer !== 'string' || !answer.trim()) {
      return new Response(JSON.stringify({ error: 'AI provider returned an empty answer' }), {
        status: 502,
        headers: jsonHeaders,
      });
    }

    return new Response(JSON.stringify({ answer: answer.trim() }), {
      status: 200,
      headers: jsonHeaders,
    });
  } catch (_error) {
    return new Response(JSON.stringify({ error: 'Unexpected AI service error' }), {
      status: 500,
      headers: jsonHeaders,
    });
  }
});
