import { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { getRecipes, deleteRecipe, updateRecipe, getPantry, checkIngredients, type Recipe, type PantryItem } from "@/lib/supabaseStore";
import { Trash2, ChefHat, Plus, User, UtensilsCrossed, Star, CheckCircle2, Clock, ShoppingCart, ArrowLeft, CookingPot, Cake, LayoutGrid } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";
import { useToast } from "@/hooks/use-toast";

export default function Recipes() {
  const { signOut } = useAuth();
  const navigate = useNavigate();
  const { toast } = useToast();
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  const [pantry, setPantry] = useState<PantryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);

  const load = async () => {
    try {
      const [recipesData, pantryData] = await Promise.all([getRecipes(), getPantry()]);
      setPantry(pantryData);
      
      // Sort: favorites first, then by date
      const sorted = [...recipesData].sort((a, b) => {
        if (a.isFavorite === b.isFavorite) {
          return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
        }
        return a.isFavorite ? -1 : 1;
      });
      setRecipes(sorted);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const handleDelete = async (id: string) => {
    try {
      await deleteRecipe(id);
      load();
    } catch (err: unknown) {
      console.error("Error deleting recipe:", err);
    }
  };

  const toggleFavorite = async (recipe: Recipe) => {
    try {
      await updateRecipe({ id: recipe.id, isFavorite: !recipe.isFavorite });
      load();
    } catch (err: unknown) {
      toast({ 
        title: "Erro ao favoritar", 
        description: "Ocorreu um problema ao salvar seu favorito.",
        variant: "destructive" 
      });
    }
  };

  return (
    <div className="min-h-screen pb-24 bg-background">
      <div className="sticky top-0 z-30 bg-background/80 backdrop-blur-md border-b border-border shadow-sm">
        <header className="px-5 pt-8 pb-4 flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">
              {selectedCategory ? selectedCategory : "Minhas Receitas"}
            </h1>
            <p className="text-muted-foreground mt-1 text-xs">
              {selectedCategory ? `Explorando seus ${selectedCategory.toLowerCase()}` : "O que vamos preparar?"}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <Link to="/profile">
              <Button variant="ghost" size="icon" className="text-muted-foreground rounded-full bg-muted w-10 h-10">
                <User className="h-5 w-5" />
              </Button>
            </Link>
          </div>
        </header>

        <div className="px-5 pb-4">
          {/* Header already has the action button pinned */}
        </div>
      </div>

      <div className="px-5 pt-6 space-y-6">
        {!selectedCategory && (
          <button
            onClick={() => navigate("/add")}
            className="w-full bg-secondary text-secondary-foreground p-4 rounded-2xl flex items-center justify-between group overflow-hidden relative shadow-sm hover:shadow-md transition-all mb-2"
          >
            <div className="relative z-10 text-left">
              <p className="text-lg font-bold">Nova Receita</p>
              <p className="text-xs opacity-90">Importe do YouTube ou crie manualmente</p>
            </div>
            <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center relative z-10">
              <Plus className="h-6 w-6 text-white" />
            </div>
            <UtensilsCrossed className="absolute -right-4 -bottom-4 h-24 w-24 opacity-10 group-hover:scale-110 transition-transform" />
          </button>
        )}

        {!selectedCategory && (
          <div className="grid grid-cols-2 gap-4">
            <button
              onClick={() => setSelectedCategory("Todos")}
              className="aspect-square bg-card border border-border rounded-3xl flex flex-col items-center justify-center gap-3 shadow-sm hover:shadow-md transition-all group"
            >
              <div className="w-16 h-16 rounded-full bg-muted/30 flex items-center justify-center group-hover:scale-110 transition-transform">
                <LayoutGrid className="h-8 w-8 text-foreground" />
              </div>
              <span className="font-bold text-lg">Todos</span>
            </button>
            <button
              onClick={() => setSelectedCategory("Favoritos")}
              className="aspect-square bg-card border border-border rounded-3xl flex flex-col items-center justify-center gap-3 shadow-sm hover:shadow-md transition-all group"
            >
              <div className="w-16 h-16 rounded-full bg-white border border-border flex items-center justify-center group-hover:scale-110 transition-transform">
                <Star className="h-8 w-8 text-foreground" />
              </div>
              <span className="font-bold text-lg">Favoritos</span>
            </button>
            <button
              onClick={() => setSelectedCategory("Salgados")}
              className="aspect-square bg-card border border-border rounded-3xl flex flex-col items-center justify-center gap-3 shadow-sm hover:shadow-md transition-all group"
            >
              <div className="w-16 h-16 rounded-full bg-muted/30 flex items-center justify-center group-hover:scale-110 transition-transform">
                <CookingPot className="h-8 w-8 text-foreground" />
              </div>
              <span className="font-bold text-lg">Salgados</span>
            </button>
            <button
              onClick={() => setSelectedCategory("Doces")}
              className="aspect-square bg-card border border-border rounded-3xl flex flex-col items-center justify-center gap-3 shadow-sm hover:shadow-md transition-all group"
            >
              <div className="w-16 h-16 rounded-full bg-muted/30 flex items-center justify-center group-hover:scale-110 transition-transform">
                <Cake className="h-8 w-8 text-foreground" />
              </div>
              <span className="font-bold text-lg">Doces</span>
            </button>
          </div>
        )}

        {selectedCategory && (
          <Button 
            variant="ghost" 
            size="sm" 
            onClick={() => setSelectedCategory(null)} 
            className="gap-1 -ml-2 text-muted-foreground"
          >
            <ArrowLeft className="h-4 w-4" /> Todas as categorias
          </Button>
        )}

        <div className="space-y-4">
          {loading ? (
            <p className="text-center py-20 text-muted-foreground">Carregando...</p>
          ) : !selectedCategory ? null : recipes.filter(r => {
            if (selectedCategory === "Todos") return true;
            if (selectedCategory === "Favoritos") return r.isFavorite;
            return r.category === selectedCategory;
          }).length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-center bg-muted/20 border border-dashed border-border rounded-2xl">
              <ChefHat className="h-10 w-10 text-muted-foreground opacity-50 mb-4" />
              <p className="text-muted-foreground text-lg">Nenhuma receita nesta categoria</p>
              <Button variant="link" onClick={() => navigate("/add")} className="mt-2">
                Adicionar primeira {selectedCategory.toLowerCase().replace(/s$/, "")}
              </Button>
            </div>
          ) : (
            recipes
              .filter(r => {
                if (selectedCategory === "Todos") return true;
                if (selectedCategory === "Favoritos") return r.isFavorite;
                return r.category === selectedCategory;
              })
              .map((recipe) => {
              const checked = checkIngredients(recipe.ingredients, pantry);
              const haveCount = checked.filter((i) => i.sufficient).length;
              const totalCount = recipe.ingredients.length;
              const allIngredientsAvailable = haveCount === totalCount;

              return (
                <Link key={recipe.id} to={`/recipe/${recipe.id}`} className="block">
                  <div className="bg-card rounded-2xl border border-border overflow-hidden hover:shadow-md transition-all relative">
                    <div className="p-4">
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex-1 min-w-0">
                          <h2 className="font-display text-lg font-bold uppercase truncate pr-8">{recipe.title}</h2>
                          
                          <div className="flex items-center gap-2 mt-1">
                            <p className="text-[10px] uppercase tracking-wider font-bold text-muted-foreground">
                              {totalCount} ingredientes
                            </p>
                            <span className="text-muted-foreground/30 text-[10px]">•</span>
                            <div className={`flex items-center gap-1 text-[10px] font-bold px-1.5 py-0.5 rounded ${
                              allIngredientsAvailable 
                                ? "bg-green-100 text-green-700" 
                                : haveCount > 0 
                                  ? "bg-amber-100 text-amber-700" 
                                  : "bg-muted text-muted-foreground"
                            }`}>
                              {allIngredientsAvailable ? (
                                <CheckCircle2 className="h-2.5 w-2.5" />
                              ) : (
                                <ShoppingCart className="h-2.5 w-2.5" />
                              )}
                              {haveCount}/{totalCount} disponíveis
                            </div>
                          </div>
                        </div>
                        <div className="flex items-center gap-1 shrink-0">
                          <button
                            onClick={(e) => { e.preventDefault(); e.stopPropagation(); toggleFavorite(recipe); }}
                            className={`p-2 rounded-full transition-all ${recipe.isFavorite ? 'text-amber-500 bg-amber-50' : 'text-muted-foreground hover:bg-muted'}`}
                          >
                            <Star className={`h-5 w-5 ${recipe.isFavorite ? 'fill-current' : ''}`} />
                          </button>
                          <button
                            onClick={(e) => { e.preventDefault(); e.stopPropagation(); handleDelete(recipe.id); }}
                            className="p-2 text-muted-foreground hover:text-destructive hover:bg-destructive/10 rounded-full transition-all"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                    
                    {/* Status Bar */}
                    <div className={`px-4 py-2 flex items-center gap-2 border-t border-border/50 text-xs font-medium ${
                      recipe.status === "reservada" ? "bg-amber-50 text-amber-700" : 
                      recipe.status === "concluida" ? "bg-green-50 text-green-700" : 
                      "bg-muted/30 text-muted-foreground"
                    }`}>
                      {recipe.status === "reservada" ? (
                        <><Clock className="h-3 w-3" /> Reservada para preparar</>
                      ) : recipe.status === "concluida" ? (
                        <><CheckCircle2 className="h-3 w-3" /> Receita concluída</>
                      ) : (
                        <><ChefHat className="h-3 w-3" /> Nova receita</>
                      )}
                    </div>
                  </div>
                </Link>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}
