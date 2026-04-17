import { serve } from "std/server";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform",
};

async function callAI(content: string): Promise<Record<string, unknown>> {
  const geminiKey = Deno.env.get("GEMINI_API_KEY");
  const groqKey = Deno.env.get("GROQ_API_KEY");

  const prompt = `Você é um extrator de receitas fiel. Sua tarefa é ler o texto abaixo e extrair a receita original no formato JSON exato: { "title": "", "description": "", "category": "Salgados", "ingredients": [{"name": "", "quantity": ""}], "instructions": "" }. Idioma: Português. Use SOMENTE as informações do texto.\n\nTEXTO:\n${content.slice(0, 15000)}`;

  // Titular: Gemini 1.5 Flash (Rápido e robusto com texto sujo)
  try {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiKey}`;
    const resp = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] })
    });
    const data: any = await resp.json();
    let text = data.candidates[0].content.parts[0].text;
    text = text.replace(/```json/g, "").replace(/```/g, "").trim();
    const match = text.match(/\{[\s\S]*\}/);
    if (match) return JSON.parse(match[0]);
  } catch (e) { console.error("Gemini failed, trying Groq..."); }

  // Reserva: Groq Llama 3 70B
  try {
    const resp = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { "Authorization": `Bearer ${groqKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "llama-3.1-70b-versatile",
        messages: [{ role: "user", content: prompt }],
        temperature: 0,
      }),
    });
    const data: any = await resp.json();
    const text = data.choices?.[0]?.message?.content || "";
    const match = text.match(/\{[\s\S]*\}/);
    if (match) return JSON.parse(match[0]);
  } catch (e) { console.error("Groq failed too"); }

  throw new Error("Não encontrei a receita original no conteúdo do vídeo. Verifique se o link possui descrição.");
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    const { url: bodyUrl, text }: { url?: string; text?: string } = await req.json();
    let content = text;

    if (!content && bodyUrl) {
      const jina = await fetch(`https://r.jina.ai/${bodyUrl}`);
      content = await jina.text();
    }

    if (!content || content.length < 50) throw new Error("Não foi possível acessar a receita.");

    const recipe = await callAI(content);
    return new Response(JSON.stringify({ recipe, url: bodyUrl }), { 
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    });

  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { 
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    });
  }
});
