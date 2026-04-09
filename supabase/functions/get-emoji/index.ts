import { serve } from "std/server";

interface GeminiResponse {
  candidates?: Array<{
    content?: {
      parts?: Array<{
        text?: string;
      }>;
    };
  }>;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};

// Lista de ícones Lucide disponíveis no frontend
const AVAILABLE_ICONS = [
  "Beef", "Egg", "Fish", "Milk", "Apple", "Leaf", "Coffee", "Cookie",
  "Pizza", "Sandwich", "Beer", "Flame", "Droplets", "Cherry", "ChefHat",
  "Wheat", "Grape", "IceCream2", "Carrot", "Salad", "Soup", "Package",
  "Banana", "Nut", "Citrus", "CookingPot", "Utensils",
];

const GEMINI_CONFIGS = [
  { version: "v1", model: "gemini-1.5-flash" },
  { version: "v1beta", model: "gemini-1.5-flash" },
  { version: "v1beta", model: "gemini-2.0-flash-lite" },
];

async function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function callGemini(apiKey: string, prompt: string, attempt = 0, isRetry = false): Promise<string> {
  if (attempt >= GEMINI_CONFIGS.length) return "ChefHat";

  const { version, model } = GEMINI_CONFIGS[attempt];

  try {
    const resp = await fetch(
      `https://generativelanguage.googleapis.com/${version}/models/${model}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.1, maxOutputTokens: 20 },
        }),
      }
    );

    if (resp.status === 503 || resp.status === 429) {
      if (!isRetry) {
        await sleep(2000);
        return callGemini(apiKey, prompt, attempt, true);
      }
    }

    if (!resp.ok) return callGemini(apiKey, prompt, attempt + 1);

    const data: GeminiResponse = await resp.json();
    const text = (data.candidates?.[0]?.content?.parts?.[0]?.text || "").trim();

    // Extrair apenas o nome do ícone da resposta
    const iconName = text.replace(/[^a-zA-Z0-9]/g, "");
    if (AVAILABLE_ICONS.includes(iconName)) return iconName;

    // Tentar encontrar parcialmente na resposta
    const found = AVAILABLE_ICONS.find(icon => text.includes(icon));
    return found || "Utensils";
  } catch {
    return callGemini(apiKey, prompt, attempt + 1);
  }
}

serve(async (req: any) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    const { ingredient }: any = await req.json();
    if (!ingredient) throw new Error("Ingredient is required");

    const apiKey = Deno.env.get("GEMINI_API_KEY")?.trim();
    if (!apiKey || !apiKey.startsWith("AIza")) {
      return new Response(JSON.stringify({ icon: "Utensils" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const prompt = `Dado o ingrediente culinário: "${ingredient}"
Escolha o ícone mais adequado desta lista: ${AVAILABLE_ICONS.join(", ")}
Responda APENAS com o nome exato do ícone.`;

    const icon = await callGemini(apiKey, prompt);

    return new Response(JSON.stringify({ icon }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (_e) {
    return new Response(JSON.stringify({ icon: "Utensils" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
