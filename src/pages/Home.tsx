import { useNavigate } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import { ChefHat, UtensilsCrossed, ShoppingCart, User, Settings, HelpCircle, Info, LogOut, Moon, Sun } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { useTheme } from "next-themes";

export default function Home() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { toast } = useToast();
  const { theme, setTheme } = useTheme();

  const handleLogout = async () => {
    await supabase.auth.signOut();
    toast({ title: "Até logo!", description: "Você saiu da sua conta." });
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Header */}
      <header className="flex items-center justify-between px-5 pt-8 pb-4">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 bg-foreground rounded-2xl flex items-center justify-center">
            <ChefHat className="h-7 w-7 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-foreground" style={{ fontFamily: 'var(--font-display)' }}>
              Meu Cozinheiro
            </h1>
            <p className="text-sm text-muted-foreground">O que deseja fazer?</p>
          </div>
        </div>

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button className="w-10 h-10 rounded-full bg-muted flex items-center justify-center hover:bg-muted/80 transition-colors">
              <User className="h-5 w-5 text-foreground" />
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-48 bg-background border border-border">
            <DropdownMenuItem onClick={() => toast({ title: "Perfil", description: "Em breve!" })} className="gap-2 cursor-pointer">
              <User className="h-4 w-4" /> Perfil
            </DropdownMenuItem>
            <DropdownMenuItem onSelect={(e) => e.preventDefault()} className="gap-2 cursor-pointer justify-between">
              <span className="flex items-center gap-2">
                {theme === "dark" ? <Moon className="h-4 w-4" /> : <Sun className="h-4 w-4" />}
                Modo Escuro
              </span>
              <Switch
                checked={theme === "dark"}
                onCheckedChange={(checked) => setTheme(checked ? "dark" : "light")}
              />
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => toast({ title: "Ajuda", description: "Em breve!" })} className="gap-2 cursor-pointer">
              <HelpCircle className="h-4 w-4" /> Ajuda
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => toast({ title: "Sobre", description: "Meu Cozinheiro v1.0" })} className="gap-2 cursor-pointer">
              <Info className="h-4 w-4" /> Sobre
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={handleLogout} className="gap-2 cursor-pointer text-destructive focus:text-destructive">
              <LogOut className="h-4 w-4" /> Sair
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </header>

      {/* Main buttons */}
      <div className="flex-1 flex flex-col gap-4 px-5 pt-8 pb-24">
        <button
          onClick={() => navigate("/add")}
          className="flex-1 min-h-[180px] rounded-2xl border-2 border-border bg-background hover:bg-muted/50 transition-all flex flex-col items-center justify-center gap-4 group"
        >
          <div className="w-16 h-16 bg-foreground rounded-2xl flex items-center justify-center group-hover:scale-105 transition-transform">
            <UtensilsCrossed className="h-8 w-8 text-white" />
          </div>
          <div className="text-center">
            <p className="text-lg font-semibold text-foreground">Adicionar Receita</p>
            <p className="text-sm text-muted-foreground mt-1">Crie ou importe uma nova receita</p>
          </div>
        </button>

        <button
          onClick={() => navigate("/pantry")}
          className="flex-1 min-h-[180px] rounded-2xl border-2 border-border bg-background hover:bg-muted/50 transition-all flex flex-col items-center justify-center gap-4 group"
        >
          <div className="w-16 h-16 bg-foreground rounded-2xl flex items-center justify-center group-hover:scale-105 transition-transform">
            <ShoppingCart className="h-8 w-8 text-white" />
          </div>
          <div className="text-center">
            <p className="text-lg font-semibold text-foreground">Adicionar à Despensa</p>
            <p className="text-sm text-muted-foreground mt-1">Registre itens de mercado</p>
          </div>
        </button>
      </div>
    </div>
  );
}
