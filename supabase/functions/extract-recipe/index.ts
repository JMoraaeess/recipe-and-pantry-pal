import { serve } from "std/server";

interface YouTubeData {
  title?: string;
  videoDetails?: {
    shortDescription?: string;
    title?: string;
  };
  engagementPanels?: any[];
}

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
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};

function extractYouTubeVideoId(url: string): string | null {
  const match = url.match(
    /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/|youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})/
  );
  return match ? match[1] : null;
}

function isYouTubeUrl(url: string): boolean {
  return /(?:youtube\.com|youtu\.be)/i.test(url);
}

function ensureHttps(url: string): string {
  let u = url.trim();
  if (!u.startsWith("http://") && !u.startsWith("https://")) {
    u = "https://" + u;
  }
  return u;
}

async function fetchYouTubeContent(videoId: string): Promise<string> {
  console.log(`[YouTube] Iniciando extração do vídeo: ${videoId}`);
  let title = "";
  try {
    const oembedResp = await fetch(
      `https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoId}&format=json`
    );
    if (oembedResp.ok) {
      const oembedData: any = await oembedResp.json();
      title = oembedData.title || "";
      console.log(`[YouTube] Título via oEmbed: ${title}`);
    }
  } catch (e) { console.error("[YouTube] Falha oEmbed:", e); }

  const pageResp = await fetch(`https://www.youtube.com/watch?v=${videoId}`, {
    headers: {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      "Accept-Language": "pt-BR,pt;q=0.9,en;q=0.8",
      "Accept": "text/html,application/xhtml+xml",
    },
  });

  if (!pageResp.ok) {
    throw new Error(`Falha ao acessar YouTube (${pageResp.status})`);
  }

  const html = await pageResp.text();
  console.log(`[YouTube] HTML recebido (${html.length} bytes)`);

  let description = "";
  const playerMatch = html.match(/var\s+ytInitialPlayerResponse\s*=\s*(\{.+?\})\s*;\s*(?:var|<\/script)/s);
  if (playerMatch) {
    try {
      const playerData: YouTubeData = JSON.parse(playerMatch[1]);
      description = playerData?.videoDetails?.shortDescription || "";
      if (!title) title = playerData?.videoDetails?.title || "";
      console.log(`[YouTube] Descrição encontrada via playerResponse (${description.length} chars)`);
    } catch (e) { console.error("[YouTube] Erro parse ytInitialPlayerResponse", e); }
  }

  if (!description) {
    const dataMatch = html.match(/var\s+ytInitialData\s*=\s*(\{.+?\})\s*;\s*(?:var|<\/script)/s);
    if (dataMatch) {
      try {
        const initData: YouTubeData = JSON.parse(dataMatch[1]);
        const panels = initData?.engagementPanels || [];
        for (const panel of panels) {
          const content = panel?.engagementPanelSectionListRenderer?.content?.structuredDescriptionContentRenderer?.items;
          if (content) {
            for (const item of content) {
              const desc = item?.expandableVideoDescriptionBodyRenderer?.attributedDescriptionBodyText?.content ||
                           item?.videoDescriptionHeaderRenderer?.attributedDescriptionBodyText?.content;
              if (desc) { description = desc; break; }
            }
          }
        }
      } catch (e) { console.error("[YouTube] Erro parse ytInitialData", e); }
    }
  }

  let transcript = "";
  try {
    const captionMatch = html.match(/"captionTracks"\s*:\s*(\[.*?\])/s);
    if (captionMatch) {
      const tracks = JSON.parse(captionMatch[1]);
      const ptTrack = tracks.find((t: any) => t.languageCode === "pt" || t.languageCode === "pt-BR");
      const autoTrack = tracks.find((t: any) => t.kind === "asr");
      const track = ptTrack || autoTrack || tracks[0];

      if (track?.baseUrl) {
        const captionResp = await fetch(track.baseUrl);
        if (captionResp.ok) {
          const captionXml = await captionResp.text();
          transcript = captionXml.replace(/<[^>]+>/g, " ").replace(/&amp;/g, "&").replace(/\s+/g, " ").trim();
        }
      }
    }
  } catch (e) { console.error("[YouTube] Erro extração de legendas", e); }

  let content = "";
  if (title) content += `TÍTULO: ${title}\n\n`;
  if (description) content += `DESCRIÇÃO:\n${description}\n\n`;
  if (transcript) content += `TRANSCRIÇÃO:\n${transcript}\n\n`;

  return content.slice(0, 20000);
}

async function fetchWebpageContent(url: string): Promise<string> {
  const pageResp = await fetch(url, {
    headers: { 
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", 
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9" 
    },
  });
  if (!pageResp.ok) throw new Error(`Falha ao acessar o site (${pageResp.status})`);
  const html = await pageResp.text();
  return html.replace(/<script[\s\S]*?<\/script>/gi, "").replace(/<style[\s\S]*?<\/style>/gi, "").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").slice(0, 12000);
}

async function callGemini(apiKey: string, systemPrompt: string, userContent: string, imageData: any = null): Promise<any> {
  const model = "gemini-1.5-flash";
  const url = `https://generativelanguage.googleapis.com/v1/models/${model}:generateContent?key=${apiKey}`;
  
  const textPrompt = `${systemPrompt}\n\nCONTEÚDO:\n${userContent}\n\nResponda APENAS com um JSON puro:
  {
    "title": "título",
    "description": "descrição",
    "category": "Salgados ou Doces",
    "ingredients": [{"name": "item", "quantity": "qtd"}],
    "instructions": "passos numerados",
    "error": null
  }`;

  const parts: any[] = [{ text: textPrompt }];
  if (imageData) parts.push({ inlineData: { mimeType: imageData.mimeType, data: imageData.data } });

  const resp = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts }],
      generationConfig: { temperature: 0.1 }
    }),
  });

  if (!resp.ok) throw new Error(`Erro IA: ${resp.status}`);
  const data: GeminiResponse = await resp.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text || "";
  
  const startIdx = text.indexOf("{");
  const endIdx = text.lastIndexOf("}");
  if (startIdx === -1) throw new Error("JSON Inválido");
  return JSON.parse(text.substring(startIdx, endIdx + 1));
}

serve(async (req: any) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    const { url: rawUrl, image: rawImage }: any = await req.json();
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) throw new Error("GEMINI_API_KEY não configurada");

    let contentForAI = "";
    let sourceType = "";
    let imageData: any = null;

    if (rawImage) {
      sourceType = "image";
      contentForAI = "Extraia desta imagem.";
      const base64Data = rawImage.includes(",") ? rawImage.split(",")[1] : rawImage;
      const mime = rawImage.includes(":") ? rawImage.split(":")[1].split(";")[0] : "image/jpeg";
      imageData = { mimeType: mime, data: base64Data };
    } else if (rawUrl) {
      const url = ensureHttps(rawUrl);
      if (isYouTubeUrl(url)) {
        sourceType = "YouTube";
        const id = extractYouTubeVideoId(url);
        if (!id) throw new Error("YouTube ID inválido");
        contentForAI = await fetchYouTubeContent(id);
      } else {
        sourceType = "Wesite";
        contentForAI = await fetchWebpageContent(url);
      }
    }

    const systemPrompt = `Extraia a receita do conteúdo de ${sourceType}. Idioma: Português.`;
    const result = await callGemini(apiKey, systemPrompt, contentForAI, imageData);

    return new Response(JSON.stringify({ recipe: result }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (e: any) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
