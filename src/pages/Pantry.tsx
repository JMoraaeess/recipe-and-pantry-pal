import { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { getPantry, removePantryItem, type PantryItem } from "@/lib/supabaseStore";
import { formatQuantity } from "@/lib/units";
import { Button } from "@/components/ui/button";
import { X, Apple, Plus, ArrowLeft, Calendar, User, Package, Milk, CupSoda, Flame, Sparkles, UtensilsCrossed, Beef, Sandwich, LayoutGrid, Leaf } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { format, isBefore, startOfDay, addDays } from "date-fns";
import { ptBR } from "date-fns/locale";
import { IngredientIcon } from "@/components/IngredientIcon";
import { capitalize } from "@/lib/utils";

export default function Pantry() {
  const { toast } = useToast();
  const navigate = useNavigate();
  const [pantry, setPantry] = useState<PantryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);

  const load = async () => {
    try {
      setPantry(await getPantry());
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const handleRemove = async (id: string) => {
    try {
      await removePantryItem(id);
      load();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Algo deu errado.";
      toast({ title: "Erro", description: message, variant: "destructive" });
    }
  };

  return (
    <div className="min-h-screen pb-24 bg-background">
      <div className="sticky top-0 z-30 bg-background/80 backdrop-blur-md border-b border-border shadow-sm">
        <header className="px-5 pt-8 pb-4 flex items-start justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">
              {selectedCategory ? selectedCategory : "Minha Despensa"}
            </h1>
            <p className="text-muted-foreground mt-1 text-xs">
              {selectedCategory ? `Itens em ${selectedCategory.toLowerCase()}` : "O que você tem em casa?"}
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
            onClick={() => navigate("/add-pantry")}
            className="w-full bg-secondary text-secondary-foreground p-4 rounded-2xl flex items-center justify-between group overflow-hidden relative shadow-sm hover:shadow-md transition-all mb-2"
          >
            <div className="relative z-10 text-left">
              <p className="text-lg font-bold">Novo Item</p>
              <p className="text-xs opacity-90">Adicione ingredientes que você comprou</p>
            </div>
            <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center relative z-10">
              <Plus className="h-6 w-6 text-white" />
            </div>
            <Apple className="absolute -right-4 -bottom-4 h-24 w-24 opacity-10 group-hover:scale-110 transition-transform" />
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
            <button onClick={() => setSelectedCategory("Proteínas")} className="aspect-square bg-card border border-border rounded-3xl flex flex-col items-center justify-center gap-3 shadow-sm hover:shadow-md transition-all group">
              <div className="w-16 h-16 rounded-full bg-muted/30 flex items-center justify-center group-hover:scale-110 transition-transform">
                <Beef className="h-8 w-8 text-foreground" />
              </div>
              <span className="font-bold text-lg">Proteínas</span>
            </button>
            <button onClick={() => setSelectedCategory("Frios")} className="aspect-square bg-card border border-border rounded-3xl flex flex-col items-center justify-center gap-3 shadow-sm hover:shadow-md transition-all group">
              <div className="w-16 h-16 rounded-full bg-muted/30 flex items-center justify-center group-hover:scale-110 transition-transform">
                <Sandwich className="h-8 w-8 text-foreground" />
              </div>
              <span className="font-bold text-lg">Frios</span>
            </button>
            <button onClick={() => setSelectedCategory("Hortifruti")} className="aspect-square bg-card border border-border rounded-3xl flex flex-col items-center justify-center gap-3 shadow-sm hover:shadow-md transition-all group">
              <div className="w-16 h-16 rounded-full bg-muted/30 flex items-center justify-center group-hover:scale-110 transition-transform">
                <Apple className="h-8 w-8 text-foreground" />
              </div>
              <span className="font-bold text-lg">Hortifruti</span>
            </button>
            <button onClick={() => setSelectedCategory("Mercearia")} className="aspect-square bg-card border border-border rounded-3xl flex flex-col items-center justify-center gap-3 shadow-sm hover:shadow-md transition-all group">
              <div className="w-16 h-16 rounded-full bg-muted/30 flex items-center justify-center group-hover:scale-110 transition-transform">
                <Package className="h-8 w-8 text-foreground" />
              </div>
              <span className="font-bold text-lg">Mercearia</span>
            </button>
            <button onClick={() => setSelectedCategory("Laticínios")} className="aspect-square bg-card border border-border rounded-3xl flex flex-col items-center justify-center gap-3 shadow-sm hover:shadow-md transition-all group">
              <div className="w-16 h-16 rounded-full bg-muted/30 flex items-center justify-center group-hover:scale-110 transition-transform">
                <Milk className="h-8 w-8 text-foreground" />
              </div>
              <span className="font-bold text-lg">Laticínios</span>
            </button>
            <button onClick={() => setSelectedCategory("Bebidas")} className="aspect-square bg-card border border-border rounded-3xl flex flex-col items-center justify-center gap-3 shadow-sm hover:shadow-md transition-all group">
              <div className="w-16 h-16 rounded-full bg-muted/30 flex items-center justify-center group-hover:scale-110 transition-transform">
                <CupSoda className="h-8 w-8 text-foreground" />
              </div>
              <span className="font-bold text-lg">Bebidas</span>
            </button>
            <button onClick={() => setSelectedCategory("Temperos")} className="aspect-square bg-card border border-border rounded-3xl flex flex-col items-center justify-center gap-3 shadow-sm hover:shadow-md transition-all group">
              <div className="w-16 h-16 rounded-full bg-muted/30 flex items-center justify-center group-hover:scale-110 transition-transform">
                <Leaf className="h-8 w-8 text-foreground" />
              </div>
              <span className="font-bold text-lg">Temperos</span>
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

        <div className="space-y-3">
          {loading ? (
            <p className="text-center py-20 text-muted-foreground">Carregando...</p>
          ) : !selectedCategory ? null : pantry.filter(i => selectedCategory === "Todos" || i.category === selectedCategory).length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-center bg-muted/20 border border-dashed border-border rounded-2xl">
              <div className="h-20 w-20 rounded-full bg-muted flex items-center justify-center mb-4">
                <Apple className="h-10 w-10 text-muted-foreground opacity-50" />
              </div>
              <p className="text-muted-foreground text-lg">Nenhum item em {selectedCategory.toLowerCase()}</p>
              <Button variant="link" onClick={() => navigate("/add-pantry", { state: { category: selectedCategory === "Todos" ? "Mercearia" : selectedCategory } })} className="mt-2 text-primary font-bold">
                Adicionar item {selectedCategory !== "Todos" ? `em ${selectedCategory}` : ""}
              </Button>
            </div>
          ) : (
            <div className="space-y-3">
              {pantry
                .filter(i => selectedCategory === "Todos" || i.category === selectedCategory)
                .map((item) => {
                const available = item.numericValue != null ? item.numericValue - (item.reservedValue || 0) : null;
                const hasReservation = (item.reservedValue || 0) > 0;
                const baseUnit = item.unit || "g";
                
                const expiryDate = item.expiryDate ? new Date(item.expiryDate) : null;
                const isExpired = expiryDate ? isBefore(expiryDate, startOfDay(new Date())) : false;
                const isCloseToExpiry = expiryDate && !isExpired ? isBefore(expiryDate, addDays(new Date(), 7)) : false;

                return (
                  <div key={item.id} className="group flex items-center gap-3 bg-card border border-border rounded-2xl px-4 py-4 hover:shadow-sm transition-all">
                    <div className="h-10 w-10 rounded-xl bg-primary/5 flex items-center justify-center shrink-0 group-hover:bg-primary/10 transition-colors">
                      <IngredientIcon name={item.name} className="text-2xl" />
                    </div>
                    
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="font-semibold text-foreground truncate">{capitalize(item.name)}</p>
                        {expiryDate && (
                          <div className={`flex items-center gap-1 text-[10px] px-1.5 py-0.5 rounded-full border ${
                            isExpired 
                              ? "bg-destructive/10 text-destructive border-destructive/20" 
                              : isCloseToExpiry 
                                ? "bg-amber-100 text-amber-700 border-amber-200" 
                                : "bg-muted text-muted-foreground border-border"
                          }`}>
                            <Calendar className="h-3 w-3" />
                            {isExpired ? "Vencido" : format(expiryDate, "dd/MM", { locale: ptBR })}
                          </div>
                        )}
                      </div>
                      <div className="flex flex-wrap items-center gap-x-2 gap-y-1 text-xs text-muted-foreground mt-0.5">
                        {item.numericValue != null ? (
                          <>
                            <span className="bg-muted px-1.5 py-0.5 rounded">Total: {formatQuantity(item.numericValue, baseUnit)}</span>
                            {hasReservation && (
                              <>
                                <span className="text-amber-600 bg-amber-50 px-1.5 py-0.5 rounded border border-amber-100/50">Reservado: {formatQuantity(item.reservedValue || 0, baseUnit)}</span>
                                <span className="font-medium text-secondary bg-secondary/10 px-1.5 py-0.5 rounded">Livre: {formatQuantity(Math.max(0, available || 0), baseUnit)}</span>
                              </>
                            )}
                          </>
                        ) : item.quantity ? (
                          <span className="bg-muted px-1.5 py-0.5 rounded">{item.quantity}</span>
                        ) : (
                          <span className="bg-muted px-1.5 py-0.5 rounded italic opacity-70">Sem qtd.</span>
                        )}
                      </div>
                    </div>
                    
                    <button 
                      onClick={() => handleRemove(item.id)} 
                      className="p-2 text-muted-foreground hover:text-destructive hover:bg-destructive/10 rounded-full transition-all"
                      title="Remover item"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

