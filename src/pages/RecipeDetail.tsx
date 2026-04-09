import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  getRecipes,
  getPantry,
  checkIngredients,
  reserveIngredients,
  unreserveIngredients,
  completeRecipe,
  updateRecipe,
  type Recipe,
} from "@/lib/supabaseStore";
import { ArrowLeft, Check, ShoppingCart, ExternalLink, BookmarkCheck, ChefHat, Undo2, Star } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";
import { IngredientIcon } from "@/components/IngredientIcon";
import { capitalize } from "@/lib/utils";

const STATUS_LABELS: Record<string, { label: string; color: string }> = {
  nova: { label: "Nova", color: "bg-muted text-muted-foreground" },
  reservada: { label: "Reservada", color: "bg-accent text-accent-foreground" },
  concluida: { label: "Concluída", color: "bg-secondary text-secondary-foreground" },
};

const getYoutubeVideoId = (url: string) => {
  const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
  const match = url.match(regExp);
  return (match && match[2].length === 11) ? match[2] : null;
};

export default function RecipeDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { toast } = useToast();
  const [recipe, setRecipe] = useState<Recipe | null>(null);
  const [pantry, setPantry] = useState<PantryItem[]>([]);
  const [loading, setLoading] = useState(true);

  const reload = async () => {
    try {
      const [recipes, p] = await Promise.all([getRecipes(), getPantry()]);
      const found = recipes.find((r) => r.id === id);
      setRecipe(found || null);
      setPantry(p);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  if (loading) return <div className="min-h-screen flex items-center justify-center text-muted-foreground">Carregando...</div>;
  if (!recipe) return <div className="min-h-screen flex items-center justify-center"><p className="text-muted-foreground">Receita não encontrada</p></div>;

  const checked = checkIngredients(recipe.ingredients, pantry);
  const haveCount = checked.filter((i) => i.sufficient).length;
  const needCount = checked.filter((i) => !i.sufficient).length;
  const statusInfo = STATUS_LABELS[recipe.status] || STATUS_LABELS.nova;
  const youtubeId = recipe.source ? getYoutubeVideoId(recipe.source) : null;

  const handleReserve = async () => {
    const result = await reserveIngredients(recipe);
    await updateRecipe({ id: recipe.id, status: "reservada" });
    await reload();
    toast(result.missing.length > 0
      ? { title: "Reservada com ressalvas", description: `Faltam na despensa: ${result.missing.join(", ")}` }
      : { title: "Receita reservada!", description: "Os ingredientes foram reservados na sua despensa." });
  };

  const handleUnreserve = async () => {
    await unreserveIngredients(recipe);
    await updateRecipe({ id: recipe.id, status: "nova" });
    await reload();
    toast({ title: "Reserva cancelada", description: "Os ingredientes voltaram à despensa." });
  };

  const handleComplete = async () => {
    const result = await completeRecipe(recipe);
    await updateRecipe({ id: recipe.id, status: "concluida" });
    await reload();
    toast(result.missing.length > 0
      ? { title: "Receita concluída!", description: `Ingredientes subtraídos. Não encontrados: ${result.missing.join(", ")}` }
      : { title: "Receita concluída!", description: "Os ingredientes foram subtraídos da sua despensa." });
  };

  const handleReset = async () => {
    await updateRecipe({ id: recipe.id, status: "nova" });
    await reload();
    toast({ title: "Status resetado", description: "Receita voltou ao estado 'Nova'." });
  };

  const handleToggleFavorite = async () => {
    try {
      await updateRecipe({ id: recipe.id, isFavorite: !recipe.isFavorite });
      await reload();
      toast({ 
        title: !recipe.isFavorite ? "Adicionado aos favoritos" : "Removido dos favoritos",
        description: recipe.title 
      });
    } catch (err: unknown) {
      toast({ 
        title: "Erro ao favoritar", 
        description: "Ocorreu um problema ao salvar seu favorito.",
        variant: "destructive" 
      });
    }
  };

  return (
    <div className="min-h-screen pb-24">
      <header className="px-5 pt-6 pb-4">
        <div className="flex items-center justify-between gap-2 mb-2">
          <Button variant="ghost" size="sm" onClick={() => navigate(-1)} className="gap-1 -ml-2 text-muted-foreground">
            <ArrowLeft className="h-4 w-4" /> Voltar
          </Button>
        </div>
        <div className="flex items-center gap-2 mb-1">
          <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${statusInfo.color}`}>{statusInfo.label}</span>
        </div>
        <h1 className="text-3xl font-bold tracking-tight uppercase">{recipe.title}</h1>
        {recipe.description && <p className="text-muted-foreground mt-1">{recipe.description}</p>}
        {recipe.source && (
          <a href={recipe.source.startsWith("http") ? recipe.source : undefined} target="_blank" rel="noopener noreferrer"
            className="inline-flex items-center gap-1 text-sm text-primary mt-2 hover:underline">
            <ExternalLink className="h-3.5 w-3.5" />
            {recipe.source.startsWith("http") ? "Ver fonte" : recipe.source}
          </a>
        )}
      </header>

      <div className="px-5">
        <div className="flex items-center gap-3 mb-5">
          <div className="flex items-center gap-1.5 bg-secondary/20 rounded-full px-3 py-1.5 text-sm font-medium">
            <Check className="h-4 w-4 text-secondary" />
            <span className="text-secondary">{haveCount} tem</span>
          </div>
          <div className="flex items-center gap-1.5 bg-primary/10 text-primary rounded-full px-3 py-1.5 text-sm font-medium">
            <ShoppingCart className="h-4 w-4" />
            {needCount} falta{needCount !== 1 ? "m" : ""}
          </div>
          <Button 
            variant="ghost" 
            size="icon" 
            onClick={handleToggleFavorite}
            className={`rounded-full h-8 w-8 ml-auto ${recipe.isFavorite ? 'text-amber-500 bg-amber-50' : 'text-muted-foreground'}`}
          >
            <Star className={`h-5 w-5 ${recipe.isFavorite ? 'fill-current' : ''}`} />
          </Button>
        </div>

        {recipe.status === "nova" && (
          <div className="flex gap-2 mb-5">
            <Button onClick={handleReserve} variant="outline" className="flex-1 gap-2"><BookmarkCheck className="h-4 w-4" />Reservar</Button>
            <Button onClick={handleComplete} className="flex-1 gap-2"><ChefHat className="h-4 w-4" />Concluir</Button>
          </div>
        )}
        {recipe.status === "reservada" && (
          <div className="flex gap-2 mb-5">
            <Button onClick={handleUnreserve} variant="outline" className="flex-1 gap-2"><Undo2 className="h-4 w-4" />Cancelar Reserva</Button>
            <Button onClick={handleComplete} className="flex-1 gap-2"><ChefHat className="h-4 w-4" />Concluir</Button>
          </div>
        )}
        {recipe.status === "concluida" && (
          <div className="mb-5">
            <Button onClick={handleReset} variant="outline" className="w-full gap-2"><Undo2 className="h-4 w-4" />Voltar para Nova</Button>
          </div>
        )}

        <section className="mb-6">
          <h2 className="text-xl font-semibold mb-3">Ingredientes</h2>
          <ul className="space-y-2">
            {checked.map((ing, i) => (
              <li key={i} className={`flex items-center gap-3 p-3 rounded-lg border ${ing.sufficient ? "bg-secondary/5 border-secondary/30" : "bg-card border-border"}`}>
                <div className="flex items-center justify-center h-10 w-10 rounded-full bg-background border shadow-sm shrink-0">
                  <IngredientIcon name={ing.name} className="text-xl" />
                </div>
                <div className="flex-1 font-medium flex flex-col min-w-0">
                  <span className="truncate">{capitalize(ing.name)}</span>
                  <div className="flex items-center gap-1.5 mt-0.5 text-[11px] uppercase tracking-wider">
                    {ing.sufficient ? (
                      <span className="text-secondary font-bold flex items-center gap-1">
                        <Check className="h-3 w-3" /> Na Despensa
                      </span>
                    ) : (
                      <span className="text-primary font-bold flex items-center gap-1">
                        <ShoppingCart className="h-3 w-3" /> Comprar
                      </span>
                    )}
                  </div>
                </div>
                <div className="text-right shrink-0 pl-2">
                  {ing.quantity && <span className="text-muted-foreground font-semibold text-sm block">{ing.quantity}</span>}
                  {ing.availableDisplay && <span className="text-[10px] text-muted-foreground uppercase opacity-80">Disp: {ing.availableDisplay}</span>}
                </div>
              </li>
            ))}
          </ul>
        </section>

        {youtubeId && (
          <section className="mb-6">
            <h2 className="text-xl font-semibold mb-3">Vídeo Relacionado</h2>
            <div className="aspect-video w-full rounded-xl overflow-hidden border border-border shadow-sm">
              <iframe
                width="100%"
                height="100%"
                src={`https://www.youtube.com/embed/${youtubeId}`}
                title="YouTube video player"
                frameBorder="0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowFullScreen
              ></iframe>
            </div>
          </section>
        )}

        {recipe.instructions && (
          <section>
            <h2 className="text-xl font-semibold mb-3">Modo de Preparo</h2>
            <div className="bg-card rounded-xl p-4 border border-border whitespace-pre-wrap text-sm leading-relaxed">{recipe.instructions}</div>
          </section>
        )}
      </div>
    </div>
  );
}
