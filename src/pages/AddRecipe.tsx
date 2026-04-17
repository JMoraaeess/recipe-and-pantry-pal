import { useState, useEffect } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { saveRecipe, type Ingredient } from "@/lib/supabaseStore";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Plus, X, Link, Loader2, Mic, MicOff, Play, ClipboardText } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/integrations/supabase/client";

export default function AddRecipe() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [instructions, setInstructions] = useState("");
  const [source, setSource] = useState("");
  const [ingredients, setIngredients] = useState<Ingredient[]>([{ name: "", quantity: "" }]);
  const [urlInput, setUrlInput] = useState("");
  const [importing, setImporting] = useState(false);
  const [saving, setSaving] = useState(false);
  const [category, setCategory] = useState("Salgados");
  const [importMode, setImportMode] = useState<"url" | "voice" | "paste">("url");
  const [pasteText, setPasteText] = useState("");
  const [isListening, setIsListening] = useState(false);

  // Capturar compartilhamento do YouTube/Browser (Web Share Target)
  const [searchParams] = useSearchParams();

  useEffect(() => {
    const sharedText = searchParams.get("text") || "";
    const sharedUrl = searchParams.get("url") || "";
    const sharedTitle = searchParams.get("title") || "";
    
    const combined = `${sharedText} ${sharedUrl} ${sharedTitle}`;
    const foundUrl = combined.match(/(https?:\/\/[^\s]+)/)?.[0];

    if (foundUrl) {
      setUrlInput(foundUrl);
      toast({
        title: "Link Recebido",
        description: "Estamos processando a receita compartilhada...",
      });
      autoImport(foundUrl);
    }
  }, [searchParams]);

  const autoImport = async (url: string) => {
    setImporting(true);
    try {
      const { data, error } = await supabase.functions.invoke("extract-recipe", {
        body: { url: url.trim() },
      });
      if (data?.recipe && !error) {
        setSource(url.trim());
      }
      handleImportResult(data, error);
    } catch (err: unknown) {
      handleImportError(err);
    } finally {
      setImporting(false);
    }
  };

  const addIngredient = () => setIngredients([...ingredients, { name: "", quantity: "" }]);
  const removeIngredient = (index: number) => setIngredients(ingredients.filter((_, i) => i !== index));
  const updateIngredient = (index: number, field: keyof Ingredient, value: string) => {
    const updated = [...ingredients];
    updated[index] = { ...updated[index], [field]: value };
    setIngredients(updated);
  };

  const handleImportUrl = async () => {
    if (!urlInput.trim()) return;
    setImporting(true);
    try {
      let htmlContent = "";
      
      // Se for YouTube, tentar ler via Proxy cliente para evitar CAPTCHA do servidor
      if (urlInput.includes("youtube.com") || urlInput.includes("youtu.be")) {
        try {
          // Codetabs é mais rápido e limpo que AllOrigins para YouTube
          const proxyUrl = `https://api.codetabs.com/v1/proxy?quest=${encodeURIComponent(urlInput + "&hl=pt&gl=BR")}`;
          const res = await fetch(proxyUrl);
          const rawHtml = await res.text();
          
          if (rawHtml.length > 1000) {
             const titleMatch = rawHtml.match(/<title>([^<]+)<\/title>/);
             const title = titleMatch ? titleMatch[1] : "";
             const descMatch = rawHtml.match(/"shortDescription":"([^"]+)"/) || rawHtml.match(/"description":\{"simpleText":"([^"]+)"\}/);
             const description = descMatch ? descMatch[1].replace(/\\n/g, "\n").replace(/\\"/g, '"') : "";
             
             htmlContent = `TÍTULO: ${title}\nDESCRIÇÃO: ${description}\nHTML: ${rawHtml.slice(0, 5000)}`;
          }
        } catch (e) {
          console.error("Client proxy failed:", e);
        }
      }

      const { data, error } = await supabase.functions.invoke("extract-recipe", {
        body: { url: urlInput.trim(), text: htmlContent },
      });
      if (data?.recipe && !error) {
        setSource(urlInput.trim());
      }
      handleImportResult(data, error);
    } catch (err: unknown) {
      handleImportError(err);
    } finally {
      setImporting(false);
    }
  };

  const handleVoiceCommand = () => {
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (!SpeechRecognition) {
      toast({ title: "Não suportado", description: "Seu navegador não suporta comandos de voz.", variant: "destructive" });
      return;
    }

    const recognition = new SpeechRecognition();
    recognition.lang = "pt-BR";
    recognition.continuous = false;
    recognition.interimResults = false;

    recognition.onstart = () => setIsListening(true);
    recognition.onend = () => setIsListening(false);
    recognition.onerror = () => setIsListening(false);

    recognition.onresult = async (event: any) => {
      const transcript = event.results[0][0].transcript;
      console.log("Comando de voz:", transcript);
      
      toast({ title: "Buscando receita...", description: `Pesquisando por: "${transcript}"` });
      
      setImporting(true);
      try {
        const { data, error } = await supabase.functions.invoke("extract-recipe", {
          body: { search: transcript },
        });
        handleImportResult(data, error);
      } catch (err) {
        handleImportError(err);
      } finally {
        setImporting(false);
      }
    };

    recognition.start();
  };

  const handleImportResult = (data: any, error: any) => {
    if (error) {
      console.error("Supabase function call exception:", error);
      let errorMsg = error.message || "Erro de conexão com o servidor.";
      
      if (error.context?.status) {
        errorMsg = `Status ${error.context.status}: ${errorMsg}`;
      }
      
      toast({ 
        title: "Falha na Função", 
        description: errorMsg, 
        variant: "destructive" 
      });
      return;
    }

    if (data?.error) {
      console.error("Extraction error from IA:", data.error);
      toast({
        title: "Erro na IA",
        description: typeof data.error === 'string' ? data.error : "Não foi possível identificar a receita.",
        variant: "destructive",
      });
      return;
    }

    const recipe = data?.recipe;
    if (recipe) {
      setTitle(recipe.title || "");
      setDescription(recipe.description || "");
      setCategory(recipe.category || "Salgados");
      // Garantir que instruções seja sempre uma string, mesmo que venha como array
      let inst = recipe.instructions || "";
      if (Array.isArray(inst)) inst = inst.join("\n");
      setInstructions(String(inst).replace(/\\n/g, "\n"));
      
      setIngredients(recipe.ingredients?.length
        ? recipe.ingredients.map((i: any) => ({ name: i.name || "", quantity: i.quantity || "" }))
        : [{ name: "", quantity: "" }]);
      
      toast({ 
        title: "Receita pronta!", 
        description: importMode === "image" ? "Extraída da foto com sucesso." : "Importada do link com sucesso."
      });
    }
  };

  const handleImportError = (err: any) => {
    console.error("Import exception:", err);
    let errorMsg = "Houve um erro ao processar sua solicitação.";
    
    // Tentar extrair a mensagem de erro real vinda do Supabase Function
    if (err?.message) errorMsg = err.message;
    
    toast({ 
      title: "Erro na Importação", 
      description: errorMsg, 
      variant: "destructive" 
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    setSaving(true);
    try {
      const validIngredients = ingredients.filter((i) => i.name.trim());
      await saveRecipe({
        title: title.trim(),
        description: description.trim(),
        ingredients: validIngredients,
        instructions: instructions.trim(),
        source: source.trim() || undefined,
        status: "nova",
        isFavorite: false,
        category: category,
        createdAt: new Date().toISOString(),
      });
      toast({ title: "Receita salva!", description: `"${title}" foi adicionada às suas receitas.` });
      navigate("/recipes");
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Erro desconhecido";
      toast({ title: "Erro ao salvar", description: message, variant: "destructive" });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="min-h-screen pb-20">
      <header className="px-5 pt-8 pb-4">
        <h1 className="text-3xl font-bold tracking-tight">Nova Receita</h1>
        <p className="text-muted-foreground mt-1">Adicione manualmente ou importe de um link</p>
      </header>

      <div className="px-5 mb-6">
        <div className="bg-card rounded-xl p-5 border border-border shadow-sm">
          <div className="flex gap-2 mb-4 overflow-x-auto pb-1 scrollbar-hide">
            <Button
              variant={importMode === "url" ? "default" : "outline"}
              size="sm"
              onClick={() => setImportMode("url")}
              className="rounded-full gap-2 shrink-0"
            >
              <Link className="h-4 w-4" /> Link/Vídeo
            </Button>
            <Button
              variant={importMode === "voice" ? "default" : "outline"}
              size="sm"
              onClick={() => setImportMode("voice")}
              className="rounded-full gap-2 shrink-0"
            >
              <Mic className="h-4 w-4" /> Voz
            </Button>
            <Button
              variant={importMode === "paste" ? "default" : "outline"}
              size="sm"
              onClick={() => setImportMode("paste")}
              className="rounded-full gap-2 shrink-0"
            >
              <ClipboardText className="h-4 w-4" /> Colar Texto
            </Button>
          </div>

          {importMode === "url" && (
            <div className="space-y-3">
              <div className="flex gap-2">
                <Input value={urlInput} onChange={(e) => setUrlInput(e.target.value)} placeholder="Cole o link do YouTube" disabled={importing} className="bg-background" />
                <Button type="button" onClick={handleImportUrl} disabled={importing || !urlInput.trim()} className="shrink-0">
                  {importing ? <Loader2 className="h-4 w-4 animate-spin" /> : "Extrair"}
                </Button>
              </div>
            </div>
          )}

          {importMode === "paste" && (
            <div className="space-y-3">
              <Textarea 
                placeholder="Cole aqui o texto da receita (Ingredientes, Modo de Preparo...)" 
                className="min-h-[120px] bg-background text-sm"
                value={pasteText}
                onChange={(e) => setPasteText(e.target.value)}
                disabled={importing}
              />
              <Button type="button" onClick={handleImportPaste} disabled={importing || !pasteText.trim()} className="w-full">
                {importing ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : <Play className="h-4 w-4 mr-2" />}
                Processar com IA
              </Button>
            </div>
          )}

          {importMode === "voice" && (
            <div className="space-y-3">
              <button 
                type="button"
                onClick={handleVoiceCommand}
                disabled={importing}
                className={`w-full py-6 border-2 border-dashed border-primary/30 rounded-xl flex flex-col items-center justify-center gap-2 transition-all ${importing ? "opacity-50 pointer-events-none" : "hover:bg-primary/5"}`}
              >
                {importing ? (
                  <>
                    <Loader2 className="h-8 w-8 animate-spin text-primary" />
                    <span className="text-sm font-medium text-primary">Processando...</span>
                  </>
                ) : isListening ? (
                  <>
                    <div className="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center animate-pulse">
                      <MicOff className="h-6 w-6 text-red-600" />
                    </div>
                    <span className="text-sm font-medium text-red-600">Ouvindo... Pode falar!</span>
                  </>
                ) : (
                  <>
                    <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
                      <Mic className="h-6 w-6 text-primary" />
                    </div>
                    <span className="text-sm font-medium">Toque para falar</span>
                  </>
                )}
              </button>
            </div>
          )}
        </div>
      </div>

      <div className="px-5">
        <div className="flex items-center gap-3 mb-5">
          <div className="h-px flex-1 bg-border" />
          <span className="text-xs text-muted-foreground uppercase tracking-wider">ou preencha manualmente</span>
          <div className="h-px flex-1 bg-border" />
        </div>
      </div>

      <form onSubmit={handleSubmit} className="px-5 space-y-5">
        <div>
          <label className="text-sm font-medium mb-1.5 block">Nome da Receita *</label>
          <Input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Ex: Bolo de Cenoura" required />
        </div>
        <div>
          <label className="text-sm font-medium mb-1.5 block">Descrição</label>
          <Input value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Uma breve descrição" />
        </div>
        <div>
          <label className="text-sm font-medium mb-1.5 block">Link ou fonte (opcional)</label>
          <Input value={source} onChange={(e) => setSource(e.target.value)} placeholder="https://... ou nome do canal" />
        </div>
        <div>
          <label className="text-sm font-medium mb-1.5 block">Categoria</label>
          <div className="flex gap-2">
            {["Salgados", "Doces"].map((cat) => (
              <Button
                key={cat}
                type="button"
                variant={category === cat ? "default" : "outline"}
                onClick={() => setCategory(cat)}
                className="flex-1"
              >
                {cat}
              </Button>
            ))}
          </div>
        </div>
        <div>
          <div className="flex items-center justify-between mb-2">
            <label className="text-sm font-medium">Ingredientes</label>
            <Button type="button" variant="ghost" size="sm" onClick={addIngredient} className="gap-1 text-primary">
              <Plus className="h-4 w-4" /> Adicionar
            </Button>
          </div>
          <div className="space-y-2">
            {ingredients.map((ing, i) => (
              <div key={i} className="flex gap-2">
                <Input value={ing.name} onChange={(e) => updateIngredient(i, "name", e.target.value)} placeholder="Ingrediente" className="flex-1" />
                <Input value={ing.quantity} onChange={(e) => updateIngredient(i, "quantity", e.target.value)} placeholder="Qtd" className="w-24" />
                {ingredients.length > 1 && (
                  <button type="button" onClick={() => removeIngredient(i)} className="p-2 text-muted-foreground hover:text-destructive">
                    <X className="h-4 w-4" />
                  </button>
                )}
              </div>
            ))}
          </div>
        </div>
        <div>
          <label className="text-sm font-medium mb-1.5 block">Modo de Preparo</label>
          <Textarea value={instructions} onChange={(e) => setInstructions(e.target.value)} placeholder="Descreva o passo a passo..." rows={6} />
        </div>
        <Button type="submit" className="w-full" size="lg" disabled={saving}>
          {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : "Salvar Receita"}
        </Button>
      </form>
    </div>
  );
}
