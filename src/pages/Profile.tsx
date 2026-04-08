import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import { 
  ChefHat, 
  User, 
  HelpCircle, 
  Info, 
  LogOut, 
  Moon, 
  Sun, 
  ArrowLeft,
  BookOpen,
  ShoppingCart,
  Apple
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { useTheme } from "next-themes";
import { getRecipes, getPantry, checkIngredients, type Recipe } from "@/lib/supabaseStore";

export default function Profile() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { toast } = useToast();
  const { theme, setTheme } = useTheme();
  
  const [stats, setStats] = useState({
    recipesCount: 0,
    shoppingItemsCount: 0,
    pantryItemsCount: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadStats = async () => {
      try {
        const [recipes, pantry] = await Promise.all([getRecipes(), getPantry()]);
        
        let shoppingCount = 0;
        recipes.filter(r => r.status === "reservada").forEach(recipe => {
          const checked = checkIngredients(recipe.ingredients, pantry);
          shoppingCount += checked.filter(ing => !ing.sufficient).length;
        });

        setStats({
          recipesCount: recipes.length,
          shoppingItemsCount: shoppingCount,
          pantryItemsCount: pantry.length,
        });
      } catch (error) {
        console.error("Stats error:", error);
      } finally {
        setLoading(false);
      }
    };

    loadStats();
  }, []);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    toast({ title: "Até logo!", description: "Você saiu da sua conta." });
    navigate("/auth");
  };

  const displayName = user?.user_metadata?.first_name || user?.user_metadata?.display_name || "Cozinheiro";
  const email = user?.email || "";

  return (
    <div className="min-h-screen bg-background pb-24">
      <header className="px-5 pt-6 pb-4">
        <Button 
          variant="ghost" 
          size="sm" 
          onClick={() => navigate(-1)} 
          className="gap-1 -ml-2 mb-2 text-muted-foreground"
        >
          <ArrowLeft className="h-4 w-4" /> Voltar
        </Button>
        <h1 className="text-3xl font-bold tracking-tight">Meu Perfil</h1>
      </header>

      <div className="px-5 mt-4">
        {/* Profile Card */}
        <div className="bg-card rounded-2xl p-6 border border-border shadow-sm flex flex-col items-center text-center">
          <div className="w-20 h-20 bg-primary/10 rounded-full flex items-center justify-center mb-4">
            <User className="h-10 w-10 text-primary" />
          </div>
          <h2 className="text-xl font-bold text-foreground">{displayName}</h2>
          <p className="text-sm text-muted-foreground">{email}</p>
        </div>

        {/* Dashboard Stats */}
        <div className="grid grid-cols-3 gap-3 mt-6">
          <div className="bg-card p-3 rounded-2xl border border-border flex flex-col gap-2">
            <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center">
              <BookOpen className="h-4 w-4 text-blue-600" />
            </div>
            <div>
              <p className="text-xl font-bold">{stats.recipesCount}</p>
              <p className="text-[10px] text-muted-foreground uppercase font-semibold">Receitas</p>
            </div>
          </div>

          <div className="bg-card p-3 rounded-2xl border border-border flex flex-col gap-2">
            <div className="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center">
              <ShoppingCart className="h-4 w-4 text-amber-600" />
            </div>
            <div>
              <p className="text-xl font-bold">{stats.shoppingItemsCount}</p>
              <p className="text-[10px] text-muted-foreground uppercase font-semibold">Faltando</p>
            </div>
          </div>

          <div className="bg-card p-3 rounded-2xl border border-border flex flex-col gap-2">
            <div className="w-8 h-8 rounded-full bg-green-100 flex items-center justify-center">
              <Apple className="h-4 w-4 text-green-600" />
            </div>
            <div>
              <p className="text-xl font-bold">{stats.pantryItemsCount}</p>
              <p className="text-[10px] text-muted-foreground uppercase font-semibold">Despensa</p>
            </div>
          </div>
        </div>

        {/* Settings List */}
        <div className="mt-8 space-y-2">
          <div className="bg-card rounded-2xl border border-border overflow-hidden">
            <div className="flex items-center justify-between px-4 py-4 border-b border-border last:border-0">
              <div className="flex items-center gap-3">
                {theme === "dark" ? <Moon className="h-5 w-5 text-muted-foreground" /> : <Sun className="h-5 w-5 text-muted-foreground" />}
                <span className="font-medium">Modo Escuro</span>
              </div>
              <Switch
                checked={theme === "dark"}
                onCheckedChange={(checked) => setTheme(checked ? "dark" : "light")}
              />
            </div>
            
            <button 
              onClick={() => toast({ title: "Ajuda", description: "Em breve!" })}
              className="w-full flex items-center gap-3 px-4 py-4 border-b border-border last:border-0 hover:bg-muted/50 transition-colors"
            >
              <HelpCircle className="h-5 w-5 text-muted-foreground" />
              <span className="font-medium text-left">Ajuda & Suporte</span>
            </button>

            <button 
              onClick={() => toast({ title: "Sobre", description: "Meu Cozinheiro v1.0" })}
              className="w-full flex items-center gap-3 px-4 py-4 border-b border-border last:border-0 hover:bg-muted/50 transition-colors"
            >
              <Info className="h-5 w-5 text-muted-foreground" />
              <span className="font-medium text-left">Sobre o App</span>
            </button>
          </div>

          <button 
            onClick={handleLogout}
            className="w-full bg-destructive/10 text-destructive rounded-2xl flex items-center gap-3 px-4 py-4 hover:bg-destructive/20 transition-colors"
          >
            <LogOut className="h-5 w-5" />
            <span className="font-bold">Sair da Conta</span>
          </button>
        </div>
      </div>
    </div>
  );
}
