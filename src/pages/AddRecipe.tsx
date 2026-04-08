import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { saveRecipe, type Ingredient } from "@/lib/supabaseStore";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Plus, X, Link, Loader2 } from "lucide-react";
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
      if (error) throw error;
      if (data?.error) { toast({ title: "Erro", description: data.error, variant: "destructive" }); return; }
      const recipe = data.recipe;
      if (recipe?.error) {
        toast({ title: "Receita não encontrada", description: "Tente outro link ou adicione manualmente.", variant: "destructive" });
        return;
      }
      if (recipe) {
        setTitle(recipe.title || "");
        setDescription(recipe.description || "");
        setInstructions((recipe.instructions || "").replace(/\\n/g, "\n"));
        setSource(urlInput.trim());
        setIngredients(recipe.ingredients?.length
          ? recipe.ingredients.map((i: Ingredient) => ({ name: i.name || "", quantity: i.quantity || "" }))
          : [{ name: "", quantity: "" }]);
        toast({ title: "Receita importada!", description: "Revise os dados e salve." });
      }
    } catch (err: unknown) {
      console.error("Import error:", err);
      toast({ title: "Erro ao importar", description: "Não foi possível extrair a receita desse link.", variant: "destructive" });
    } finally {
      setImporting(false);
    }
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
        <div className="bg-card rounded-xl p-4 border border-border">
          <label className="text-sm font-medium mb-2 block flex items-center gap-2">
            <Link className="h-4 w-4 text-primary" />
            Importar de um link ou vídeo
          </label>
          <div className="flex gap-2">
            <Input value={urlInput} onChange={(e) => setUrlInput(e.target.value)} placeholder="https://site-de-receitas.com/... ou YouTube" disabled={importing} />
            <Button type="button" onClick={handleImportUrl} disabled={importing || !urlInput.trim()} className="shrink-0">
              {importing ? <Loader2 className="h-4 w-4 animate-spin" /> : "Importar"}
            </Button>
          </div>
          <p className="text-xs text-muted-foreground mt-2">Cole um link de site de receitas ou vídeo do YouTube e a IA preencherá tudo</p>
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
