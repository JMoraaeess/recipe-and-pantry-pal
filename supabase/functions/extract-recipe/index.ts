import { serve } from "std/server";
import { createClient } from "@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function callAI(content: string, isTitleOnly = false): Promise<Record<string, unknown>> {
  const geminiKey = Deno.env.get("GEMINI_API_KEY");
  const groqKey = Deno.env.get("GROQ_API_KEY");

  const systemPrompt = isTitleOnly 
    ? "Você recebeu apenas o título de uma receita. Sugira uma receita clássica para este prato no formato JSON."
    : "Extraia a receita do texto fornecido para o formato JSON.";

  const prompt = `${systemPrompt}
Formato: { "title": "", "description": "", "category": "Salgados", "ingredients": [{"name": "", "quantity": ""}], "instructions": "" }. 
Idioma: Português.

TEXTO/TÍTULO:
${content.slice(0, 20000)}`;

  let debugText = "";
  try {
    const resp = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { "Authorization": `Bearer ${groqKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [{ role: "user", content: prompt }],
        temperature: 0,
        response_format: { type: "json_object" }
      }),
    });
    if (resp.ok) {
      const data = await resp.json();
      let text = data.choices?.[0]?.message?.content || "";
      debugText = text;
      
      if (text.includes("```json")) {
        text = text.split("```json")[1].split("```")[0];
      } else if (text.includes("```")) {
        text = text.split("```")[1].split("```")[0];
      }
      
      const match = text.match(/\{[\s\S]*\}/);
      if (match) return JSON.parse(match[0]);
    } else {
      const errData = await resp.text();
      throw new Error(`Groq API Error: ${errData}`);
    }
  } catch (e) {
    throw new Error(`Parse Error: ${e.message} | Text: ${debugText}`);
  }

  throw new Error("Não conseguimos processar esta receita. A IA não retornou um formato válido.");
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    const { url: bodyUrl, text }: { url?: string; text?: string } = await req.json();
    
    // 1. Verificar Cache
    if (bodyUrl) {
      const { data: cached } = await supabase.from("recipe_cache").select("recipe_data").eq("url", bodyUrl).single();
      if (cached) return new Response(JSON.stringify({ recipe: cached.recipe_data, url: bodyUrl, cached: true }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    let content = text;
    
    // 2. Tentar ler via Jina com User-Agent de navegador
    if ((!content || content.length < 100) && bodyUrl) {
      try {
        const jinaResp = await fetch(`https://r.jina.ai/${bodyUrl}`, {
          headers: { 
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
          }
        });
        content = await jinaResp.text();
      } catch (e) { console.error("Jina falhou totalmente"); }
    }

    // 3. Se tudo falhou mas temos a URL, tentamos extrair o título da URL para dar uma resposta "menos pior"
    if (!content || content.length < 50) {
       // Se não tem texto nenhum, a IA não faz milagre, mas podemos tentar sugerir algo pelo título se ele vier na URL
       throw new Error("O YouTube bloqueou a leitura automática deste vídeo. Tente copiar e colar a descrição manualmente na aba MANUAL ou tente outro link.");
    }

    const recipe = await callAI(content);
    if (bodyUrl && recipe) await supabase.from("recipe_cache").upsert({ url: bodyUrl, recipe_data: recipe });

    return new Response(JSON.stringify({ recipe, url: bodyUrl, cached: false }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });

  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});
