import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { saveRecipe, type Ingredient } from "@/lib/supabaseStore";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Plus, X, Link, Loader2, Camera, Image as ImageIcon } from "lucide-react";
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
  const [importMode, setImportMode] = useState<"url" | "image">("url");

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
      const { data, error } = await supabase.functions.invoke("extract-recipe", {
        body: { url: urlInput.trim() },
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

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setImporting(true);
    try {
      // Optimização da imagem antes de enviar (redimensionar e comprimir)
      const optimizeImage = (file: File): Promise<string> => {
        return new Promise((resolve) => {
          const reader = new FileReader();
          reader.onload = (e) => {
            const img = new Image();
            img.onload = () => {
              const canvas = document.createElement("canvas");
              let width = img.width;
              let height = img.height;
              const maxSize = 1024; // Máximo de 1024px para não estourar o limite de tamanho

              if (width > height) {
                if (width > maxSize) {
                  height *= maxSize / width;
                  width = maxSize;
                }
              } else {
                if (height > maxSize) {
                  width *= maxSize / height;
                  height = maxSize;
                }
              }

              canvas.width = width;
              canvas.height = height;
              const ctx = canvas.getContext("2d");
              ctx?.drawImage(img, 0, 0, width, height);
              resolve(canvas.toDataURL("image/jpeg", 0.7));
            };
            img.src = e.target?.result as string;
          };
          reader.readAsDataURL(file);
        });
      };

      const base64 = await optimizeImage(file);

      const { data, error } = await supabase.functions.invoke("extract-recipe", {
        body: { image: base64 },
      });
      
      if (data?.recipe && !error) {
        setSource("Importado via Foto");
      }
      
      handleImportResult(data, error);
    } catch (err: unknown) {
      handleImportError(err);
    } finally {
      setImporting(false);
      // Reset input
      e.target.value = "";
    }
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
      setInstructions((recipe.instructions || "").replace(/\\n/g, "\n"));
      setIngredients(recipe.ingredients?.length
        ? recipe.ingredients.map((i: any) => ({ name: i.name || "", quantity: i.quantity || "" }))
        : [{ name: "", quantity: "" }]);
      
      toast({ 
        title: "Receita pronta!", 
        description: importMode === "image" ? "Extraída da foto com sucesso." : "Importada do link com sucesso."
      });
    }
  };

  const handleImportError = (err: unknown) => {
    console.error("Import exception:", err);
    toast({ 
      title: "Erro na IA", 
      description: "Houve um erro ao processar sua solicitação. Tente novamente.", 
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
          <div className="flex gap-4 mb-4">
            <button
              onClick={() => setImportMode("url")}
              className={`flex-1 py-2 text-sm font-medium rounded-lg transition-all flex items-center justify-center gap-2 ${importMode === "url" ? "bg-primary text-primary-foreground shadow-sm" : "bg-muted text-muted-foreground hover:bg-muted/80"}`}
            >
              <Link className="h-4 w-4" /> Link/Vídeo
            </button>
            <button
              onClick={() => setImportMode("image")}
              className={`flex-1 py-2 text-sm font-medium rounded-lg transition-all flex items-center justify-center gap-2 ${importMode === "image" ? "bg-primary text-primary-foreground shadow-sm" : "bg-muted text-muted-foreground hover:bg-muted/80"}`}
            >
              <Camera className="h-4 w-4" /> Foto ou Print
            </button>
          </div>

          {importMode === "url" ? (
            <div className="space-y-3">
              <div className="flex gap-2">
                <Input value={urlInput} onChange={(e) => setUrlInput(e.target.value)} placeholder="Cole o link do YouTube ou site" disabled={importing} className="bg-background" />
                <Button type="button" onClick={handleImportUrl} disabled={importing || !urlInput.trim()} className="shrink-0 bg-primary hover:bg-primary/90">
                  {importing ? <Loader2 className="h-4 w-4 animate-spin text-white" /> : "Importar"}
                </Button>
              </div>
              <p className="text-[11px] text-muted-foreground text-center">A IA extrai a receita do link automaticamente</p>
            </div>
          ) : (
            <div className="space-y-3">
              <input type="file" id="recipe-photo" accept="image/*" className="hidden" onChange={handleFileUpload} disabled={importing} />
              <label 
                htmlFor="recipe-photo" 
                className={`w-full py-6 border-2 border-dashed border-primary/30 rounded-xl flex flex-col items-center justify-center gap-2 cursor-pointer hover:bg-primary/5 transition-all ${importing ? "opacity-50 pointer-events-none" : ""}`}
              >
                {importing ? (
                  <>
                    <Loader2 className="h-8 w-8 animate-spin text-primary" />
                    <span className="text-sm font-medium text-primary">IA analisando sua foto...</span>
                  </>
                ) : (
                  <>
                    <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
                      <ImageIcon className="h-6 w-6 text-primary" />
                    </div>
                    <span className="text-sm font-medium">Tirar Foto ou Escolher Print</span>
                    <span className="text-[10px] text-muted-foreground">Extrai texto e contexto da imagem</span>
                  </>
                )}
              </label>
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
