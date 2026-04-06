import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

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
  // Use YouTube oEmbed for title (always works)
  let title = "";
  try {
    const oembedResp = await fetch(
      `https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoId}&format=json`
    );
    if (oembedResp.ok) {
      const oembedData = await oembedResp.json();
      title = oembedData.title || "";
    }
  } catch { /* ignore */ }

  // Fetch the full YouTube page for description and captions
  const pageResp = await fetch(`https://www.youtube.com/watch?v=${videoId}`, {
    headers: {
      "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      "Accept-Language": "pt-BR,pt;q=0.9,en;q=0.8",
      "Accept": "text/html,application/xhtml+xml",
    },
  });

  if (!pageResp.ok) {
    throw new Error(`Failed to fetch YouTube page: ${pageResp.status}`);
  }

  const html = await pageResp.text();
  console.log("YouTube HTML length:", html.length);

  // Extract description from ytInitialPlayerResponse
  let description = "";
  const playerMatch = html.match(
    /var\s+ytInitialPlayerResponse\s*=\s*(\{.+?\})\s*;\s*(?:var|<\/script)/s
  );
  if (playerMatch) {
    try {
      const playerData = JSON.parse(playerMatch[1]);
      description = playerData?.videoDetails?.shortDescription || "";
      if (!title) title = playerData?.videoDetails?.title || "";
      console.log("Found description from playerResponse, length:", description.length);
    } catch (e) {
      console.error("Failed to parse ytInitialPlayerResponse:", e);
    }
  }

  // Fallback: try ytInitialData
  if (!description) {
    const dataMatch = html.match(
      /var\s+ytInitialData\s*=\s*(\{.+?\})\s*;\s*(?:var|<\/script)/s
    );
    if (dataMatch) {
      try {
        const initData = JSON.parse(dataMatch[1]);
        // Navigate to description in engagement panel
        const panels = initData?.engagementPanels || [];
        for (const panel of panels) {
          const content =
            panel?.engagementPanelSectionListRenderer?.content
              ?.structuredDescriptionContentRenderer?.items;
          if (content) {
            for (const item of content) {
              const desc =
                item?.expandableVideoDescriptionBodyRenderer?.attributedDescriptionBodyText?.content ||
                item?.videoDescriptionHeaderRenderer?.attributedDescriptionBodyText?.content;
              if (desc) {
                description = desc;
                console.log("Found description from ytInitialData, length:", description.length);
                break;
              }
            }
          }
        }
      } catch (e) {
        console.error("Failed to parse ytInitialData:", e);
      }
    }
  }

  // Try to get captions/transcript
  let transcript = "";
  try {
    const captionMatch = html.match(/"captionTracks"\s*:\s*(\[.*?\])/s);
    if (captionMatch) {
      const tracks = JSON.parse(captionMatch[1]);
      console.log("Found caption tracks:", tracks.length);
      // Prefer Portuguese, then any auto-generated
      const ptTrack = tracks.find(
        (t: any) => t.languageCode === "pt" || t.languageCode === "pt-BR"
      );
      const autoTrack = tracks.find((t: any) => t.kind === "asr");
      const track = ptTrack || autoTrack || tracks[0];

      if (track?.baseUrl) {
        console.log("Fetching captions from:", track.baseUrl.substring(0, 80));
        const captionResp = await fetch(track.baseUrl);
        if (captionResp.ok) {
          const captionXml = await captionResp.text();
          transcript = captionXml
            .replace(/<[^>]+>/g, " ")
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, '"')
            .replace(/&#39;/g, "'")
            .replace(/\s+/g, " ")
            .trim();
          console.log("Got transcript, length:", transcript.length);
        }
      }
    } else {
      console.log("No caption tracks found in page");
    }
  } catch (e) {
    console.error("Failed to extract captions:", e);
  }

  // Build the content for AI
  let content = "";
  if (title) content += `TÍTULO DO VÍDEO: ${title}\n\n`;
  if (description) content += `DESCRIÇÃO DO VÍDEO:\n${description}\n\n`;
  if (transcript) content += `TRANSCRIÇÃO/LEGENDAS DO VÍDEO:\n${transcript}\n\n`;

  if (!description && !transcript) {
    // Last resort: just give the cleaned HTML text
    const fallbackText = html
      .replace(/<script[\s\S]*?<\/script>/gi, "")
      .replace(/<style[\s\S]*?<\/style>/gi, "")
      .replace(/<[^>]+>/g, " ")
      .replace(/\s+/g, " ")
      .slice(0, 8000);
    content += `CONTEÚDO DA PÁGINA:\n${fallbackText}\n`;
    console.log("Using fallback page text");
  }

  return content.slice(0, 15000);
}

async function fetchWebpageContent(url: string): Promise<string> {
  const pageResp = await fetch(url, {
    headers: {
      "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      Accept: "text/html",
    },
  });

  if (!pageResp.ok) {
    throw new Error(`Failed to fetch page: ${pageResp.status}`);
  }

  const html = await pageResp.text();
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, "")
    .replace(/<style[\s\S]*?<\/style>/gi, "")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .slice(0, 12000);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { url: rawUrl } = await req.json();

    if (!rawUrl || typeof rawUrl !== "string") {
      return new Response(JSON.stringify({ error: "URL is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const url = ensureHttps(rawUrl);
    console.log("Processing URL:", url);

    // Determine source type and fetch content
    let content: string;
    let sourceType: string;

    if (isYouTubeUrl(url)) {
      const videoId = extractYouTubeVideoId(url);
      if (!videoId) {
        return new Response(
          JSON.stringify({ error: "Não foi possível identificar o vídeo do YouTube. Use o formato: https://www.youtube.com/watch?v=..." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      console.log("YouTube video ID:", videoId);
      content = await fetchYouTubeContent(videoId);
      sourceType = "YouTube video";
    } else {
      content = await fetchWebpageContent(url);
      sourceType = "webpage";
    }

    console.log("Content length for AI:", content.length);

    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) {
      throw new Error("LOVABLE_API_KEY is not configured");
    }

    const systemPrompt =
      sourceType === "YouTube video"
        ? `You extract recipes from YouTube video data (title, description, and/or transcript/captions).
The user will provide whatever data was available from the video.
Even if the data is incomplete, do your best to extract or reconstruct the recipe.
If there's a transcript of someone speaking, extract the recipe steps from the spoken words.
If the description has ingredient lists or steps, use those.
Format instructions with real newlines between steps, numbered.
Always respond in Portuguese (Brazilian).
If you truly cannot find any recipe content, set the error field.`
        : `You extract recipes from webpage text.
Format instructions with real newlines between steps, numbered.
Always respond in Portuguese (Brazilian).
If you truly cannot find any recipe content, set the error field.`;

    const aiResp = await fetch(
      "https://ai.gateway.lovable.dev/v1/chat/completions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${LOVABLE_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "google/gemini-3-flash-preview",
          messages: [
            { role: "system", content: systemPrompt },
            {
              role: "user",
              content: `Extract the recipe from this ${sourceType} content:\n\n${content}`,
            },
          ],
          tools: [
            {
              type: "function",
              function: {
                name: "extract_recipe",
                description: "Extract a recipe from content",
                parameters: {
                  type: "object",
                  properties: {
                    title: { type: "string", description: "Recipe title" },
                    description: {
                      type: "string",
                      description: "Short description of the recipe",
                    },
                    ingredients: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          name: { type: "string" },
                          quantity: { type: "string" },
                        },
                        required: ["name", "quantity"],
                      },
                    },
                    instructions: {
                      type: "string",
                      description:
                        "Step by step instructions with real newlines between steps",
                    },
                    error: {
                      type: "string",
                      description:
                        "Error message if no recipe found. Only set if truly no recipe.",
                    },
                  },
                  required: ["title", "ingredients", "instructions"],
                },
              },
            },
          ],
          tool_choice: {
            type: "function",
            function: { name: "extract_recipe" },
          },
        }),
      }
    );

    if (!aiResp.ok) {
      if (aiResp.status === 429) {
        return new Response(
          JSON.stringify({
            error:
              "Limite de requisições atingido. Tente novamente em alguns segundos.",
          }),
          {
            status: 429,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
      if (aiResp.status === 402) {
        return new Response(
          JSON.stringify({
            error:
              "Créditos de IA esgotados. Adicione créditos em Settings > Workspace > Usage.",
          }),
          {
            status: 402,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
      const errText = await aiResp.text();
      console.error("AI error:", aiResp.status, errText);
      throw new Error("AI processing failed");
    }

    const aiData = await aiResp.json();

    const toolCall = aiData.choices?.[0]?.message?.tool_calls?.[0];
    let recipe;
    if (toolCall?.function?.arguments) {
      recipe =
        typeof toolCall.function.arguments === "string"
          ? JSON.parse(toolCall.function.arguments)
          : toolCall.function.arguments;
    } else {
      const msgContent = aiData.choices?.[0]?.message?.content || "";
      const jsonMatch = msgContent.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        recipe = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error("Could not extract recipe from AI response");
      }
    }

    // Clean up literal \n in instructions
    if (recipe?.instructions) {
      recipe.instructions = recipe.instructions.replace(/\\n/g, "\n");
    }

    return new Response(JSON.stringify({ recipe }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("extract-recipe error:", e);
    return new Response(
      JSON.stringify({
        error: e instanceof Error ? e.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
