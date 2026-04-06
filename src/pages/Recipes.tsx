import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { getRecipes, deleteRecipe, type Recipe } from "@/lib/supabaseStore";
import { Trash2, ChefHat, Plus, LogOut } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";

export default function Recipes() {
  const { signOut } = useAuth();
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    try {
      setRecipes(await getRecipes());
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const handleDelete = async (id: string) => {
    await deleteRecipe(id);
    load();
  };

  return (
    <div className="min-h-screen pb-20">
      <header className="px-5 pt-8 pb-4 flex items-start justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Minhas Receitas</h1>
          <p className="text-muted-foreground mt-1">Suas receitas favoritas em um só lugar</p>
        </div>
        <Button variant="ghost" size="icon" onClick={signOut} className="text-muted-foreground mt-1">
          <LogOut className="h-5 w-5" />
        </Button>
      </header>

      <div className="px-5 space-y-3">
        {loading ? (
          <p className="text-center py-20 text-muted-foreground">Carregando...</p>
        ) : recipes.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <div className="h-20 w-20 rounded-full bg-muted flex items-center justify-center mb-4">
              <ChefHat className="h-10 w-10 text-muted-foreground" />
            </div>
            <p className="text-muted-foreground text-lg mb-4">Nenhuma receita ainda</p>
            <Link to="/add">
              <Button className="gap-2">
                <Plus className="h-4 w-4" />
                Adicionar receita
              </Button>
            </Link>
          </div>
        ) : (
          recipes.map((recipe) => (
            <Link key={recipe.id} to={`/recipe/${recipe.id}`} className="block">
              <div className="bg-card rounded-xl p-4 border border-border hover:shadow-md transition-shadow">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <h2 className="font-display text-lg font-semibold">{recipe.title}</h2>
                    {recipe.description && (
                      <p className="text-muted-foreground text-sm mt-1 line-clamp-2">{recipe.description}</p>
                    )}
                    <p className="text-xs text-muted-foreground mt-2">{recipe.ingredients.length} ingredientes</p>
                  </div>
                  <button
                    onClick={(e) => { e.preventDefault(); e.stopPropagation(); handleDelete(recipe.id); }}
                    className="p-2 text-muted-foreground hover:text-destructive transition-colors"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            </Link>
          ))
        )}
      </div>
    </div>
  );
}
