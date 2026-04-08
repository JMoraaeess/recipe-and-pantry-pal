import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { ingredient } = await req.json();

    if (!ingredient || typeof ingredient !== "string") {
      return new Response(JSON.stringify({ error: "Ingredient is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
    if (!OPENAI_API_KEY) {
      throw new Error("OPENAI_API_KEY is not configured");
    }

    const systemPrompt = `Você é um mapeador ultra-rápido de Emojis para ingredientes e itens de casa. Responda APENAS com 1 único caractere Emoji que melhor represente o item fornecido e nada mais. Nenhuma palavra. Nenhuma explicação. Caso não conheça a palavra, retorne 🥘.`;

    const aiResp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: `Emoji para: ${ingredient}` },
        ],
        temperature: 0.1,
      }),
    });

    if (!aiResp.ok) {
      throw new Error("AI processing failed: " + aiResp.status);
    }

    const aiData = await aiResp.json();
    let emoji = aiData.choices?.[0]?.message?.content?.trim() || "🥘";
    
    // Ensure only the first emoji sequence is returned
    emoji = Array.from(emoji)[0] || "🥘";

    return new Response(JSON.stringify({ emoji }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("get-emoji error:", e);
    return new Response(JSON.stringify({ emoji: "🥘" }), { // fail gracefully with generic icon
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
