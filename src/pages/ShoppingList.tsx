import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { getRecipes, getPantry, checkIngredients, addPantryItem, type Recipe, type PantryItem } from "@/lib/supabaseStore";
import { ShoppingCart, CheckCircle2, User, Plus, Trash2, Check, X, Search, ChevronRight, ChefHat } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useToast } from "@/hooks/use-toast";
import { IngredientIcon } from "@/components/IngredientIcon";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

export default function ShoppingList() {
  const { toast } = useToast();
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  const [pantry, setPantry] = useState<PantryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [isSelectorOpen, setIsSelectorOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  
  // Custom list state
  const [customItems, setCustomItems] = useState<{ id: string; name: string; quantity: string; expiryDate?: string; checked: boolean }[]>(() => {
    const saved = localStorage.getItem("custom_shopping_list");
    return saved ? JSON.parse(saved) : [];
  });
  const [isAddManualOpen, setIsAddManualOpen] = useState(false);
  const [manualName, setManualName] = useState("");
  const [manualQty, setManualQty] = useState("");
  const [manualExpiry, setManualExpiry] = useState("");

  // Dialog state for adding to pantry
  const [addingItem, setAddingItem] = useState<{ id: string; name: string; quantity: string } | null>(null);
  const [purchaseQuantity, setPurchaseQuantity] = useState("");
  const [purchaseExpiry, setPurchaseExpiry] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    localStorage.setItem("custom_shopping_list", JSON.stringify(customItems));
  }, [customItems]);

  const loadData = async () => {
    try {
      setLoading(true);
      const [r, p] = await Promise.all([getRecipes(), getPantry()]);
      setRecipes(r);
      setPantry(p);
    } catch (error) {
      console.error("Error loading shopping data:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const addRecipeToCustom = (recipe: Recipe) => {
    const checked = checkIngredients(recipe.ingredients, pantry);
    const missing = checked.filter(ing => !ing.sufficient);
    
    if (missing.length === 0) {
      toast({ title: "Tudo disponível", description: "Você já tem todos os ingredientes desta receita." });
      return;
    }

    const newItems = missing.map(ing => ({
      id: crypto.randomUUID(),
      name: ing.name,
      quantity: ing.quantity,
      checked: false
    }));

    setCustomItems([...customItems, ...newItems]);
    setIsSelectorOpen(false);
    toast({ title: "Adicionado", description: `${missing.length} itens de "${recipe.title}" adicionados.` });
  };

  const addAllReservedToCustom = () => {
    const reservedRecipes = recipes.filter(r => r.status === "reservada");
    let addedCount = 0;
    const newItems: { id: string; name: string; quantity: string; checked: boolean }[] = [];

    reservedRecipes.forEach(recipe => {
      const checked = checkIngredients(recipe.ingredients, pantry);
      const missing = checked.filter(ing => !ing.sufficient);
      
      missing.forEach(ing => {
        newItems.push({
          id: crypto.randomUUID(),
          name: ing.name,
          quantity: ing.quantity,
          checked: false
        });
        addedCount++;
      });
    });

    if (addedCount === 0) {
      toast({ title: "Nada para adicionar", description: "Não há receitas reservadas com itens faltando." });
      return;
    }

    setCustomItems([...customItems, ...newItems]);
    toast({ title: "Lista Atualizada", description: "Todos os itens das receitas reservadas foram adicionados." });
  };

  const handleSaveManualItem = () => {
    if (!manualName.trim()) return;
    setCustomItems([
      ...customItems,
      { 
        id: crypto.randomUUID(), 
        name: manualName.trim(), 
        quantity: manualQty.trim(), 
        expiryDate: manualExpiry || undefined,
        checked: false 
      }
    ]);
    setManualName("");
    setManualQty("");
    setManualExpiry("");
    setIsAddManualOpen(false);
  };

  const toggleCustomItem = (id: string) => {
    setCustomItems(customItems.map(item => 
      item.id === id ? { ...item, checked: !item.checked } : item
    ));
  };

  const handleItemClick = (item: { id: string; name: string; quantity: string; expiryDate?: string; checked: boolean }) => {
    if (item.checked) {
      toggleCustomItem(item.id);
    } else {
      setAddingItem(item);
      setPurchaseQuantity(item.quantity || "");
      setPurchaseExpiry(item.expiryDate || "");
    }
  };

  const handleJustCheck = () => {
    if (addingItem) {
      toggleCustomItem(addingItem.id);
      setAddingItem(null);
    }
  };

  const handleAddToPantry = async () => {
    if (!addingItem) return;
    setIsSubmitting(true);
    try {
      await addPantryItem({
        name: addingItem.name,
        quantity: purchaseQuantity?.trim() || undefined,
        expiryDate: purchaseExpiry || undefined
      });
      setCustomItems(customItems.map(item => 
        item.id === addingItem.id ? { ...item, checked: true } : item
      ));
      toast({ title: "Despensa Atualizada", description: `${addingItem.name} adicionado com sucesso.` });
      setAddingItem(null);
    } catch (e) {
      toast({ title: "Erro", description: "Não foi possível adicionar à despensa.", variant: "destructive" });
    } finally {
      setIsSubmitting(false);
    }
  };

  const removeCustomItem = (id: string) => {
    setCustomItems(customItems.filter(item => item.id !== id));
  };

  const clearCustomList = () => {
    setCustomItems([]);
    toast({ title: "Lista limpa" });
  };

  const filteredRecipes = recipes.filter(r => 
    r.title.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="min-h-screen pb-24 bg-background">
      <header className="px-5 pt-8 pb-4">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Lista de Compras</h1>
            <p className="text-muted-foreground mt-1">Sua checklist personalizada</p>
          </div>
          <Link to="/profile">
            <Button variant="ghost" size="icon" className="text-muted-foreground rounded-full bg-muted w-10 h-10">
              <User className="h-5 w-5" />
            </Button>
          </Link>
        </div>

        {/* Action Buttons */}
        <div className="grid grid-cols-2 gap-3 mt-6">
          <Button 
            onClick={addAllReservedToCustom}
            className="bg-primary text-white font-bold h-11 rounded-xl gap-2 shadow-sm"
          >
            <CheckCircle2 className="h-4 w-4" /> Todas Reservadas
          </Button>

          <Dialog open={isSelectorOpen} onOpenChange={setIsSelectorOpen}>
            <DialogTrigger asChild>
              <Button 
                variant="secondary"
                className="font-bold h-11 rounded-xl gap-2 shadow-sm"
              >
                <ChefHat className="h-4 w-4" /> Escolher Receita
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-[90vw] rounded-2xl p-0 overflow-hidden border-none">
              <DialogHeader className="p-5 pb-2">
                <DialogTitle className="text-xl font-bold">Escolha uma Receita</DialogTitle>
              </DialogHeader>
              <div className="px-5 pb-4">
                <div className="relative mb-4">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input 
                    placeholder="Buscar receita..." 
                    className="pl-9 h-10 bg-muted/50 border-none rounded-xl"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                  />
                </div>
                <div className="max-h-[60vh] overflow-y-auto space-y-2 pr-1">
                  {filteredRecipes.length === 0 ? (
                    <p className="text-center py-10 text-muted-foreground text-sm">Nenhuma receita encontrada.</p>
                  ) : (
                    filteredRecipes.map(recipe => (
                      <button
                        key={recipe.id}
                        onClick={() => addRecipeToCustom(recipe)}
                        className="w-full flex items-center justify-between p-3 rounded-xl hover:bg-muted transition-colors text-left border border-border/50"
                      >
                        <span className="font-semibold text-sm truncate">{recipe.title}</span>
                        <ChevronRight className="h-4 w-4 text-muted-foreground shrink-0" />
                      </button>
                    ))
                  )}
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </header>

      <div className="px-5 space-y-6 mt-2">
        {/* Manual Add Button */}
        <Button 
          onClick={() => setIsAddManualOpen(true)}
          className="w-full bg-card hover:bg-muted text-foreground border-border border shadow-sm rounded-2xl h-14 flex items-center justify-center gap-2 transition-colors"
        >
          <Plus className="h-5 w-5 text-primary" />
          <span className="font-bold">Adicionar Item Manual</span>
        </Button>

        {/* Checklist */}
        <div className="space-y-2">
          <div className="flex items-center justify-between px-1">
            <h2 className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Itens na Lista</h2>
            {customItems.length > 0 && (
              <button 
                onClick={clearCustomList}
                className="text-[10px] font-bold text-destructive hover:underline"
              >
                Limpar tudo
              </button>
            )}
          </div>

          {loading ? (
            <p className="text-center py-20 text-muted-foreground">Carregando...</p>
          ) : customItems.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-center bg-muted/20 border border-dashed border-border rounded-2xl">
              <div className="h-16 w-16 rounded-full bg-muted flex items-center justify-center mb-4">
                <ShoppingCart className="h-8 w-8 text-muted-foreground opacity-50" />
              </div>
              <p className="text-muted-foreground text-sm">Sua lista está vazia.</p>
              <p className="text-[10px] text-muted-foreground mt-1 px-10">Adicione itens manualmente ou use os botões acima para importar de receitas.</p>
            </div>
          ) : (
            <div className="space-y-2">
              {customItems.map((item) => (
                <div 
                  key={item.id} 
                  className={`flex items-center gap-3 p-4 rounded-2xl border transition-all ${
                    item.checked ? "bg-muted/30 border-transparent opacity-60" : "bg-card border-border shadow-sm"
                  }`}
                >
                  <button 
                    onClick={() => handleItemClick(item)}
                    className={`h-6 w-6 rounded-full border-2 flex items-center justify-center transition-colors ${
                      item.checked ? "bg-green-500 border-green-500 text-white" : "border-muted-foreground/30"
                    }`}
                  >
                    {item.checked && <Check className="h-3.5 w-3.5" />}
                  </button>
                  <div className="flex-1 min-w-0" onClick={() => handleItemClick(item)}>
                    <div className="flex items-center justify-between gap-2">
                      <p className={`flex items-center gap-2 text-base font-bold truncate ${item.checked ? "line-through text-muted-foreground" : "text-foreground"}`}>
                        <IngredientIcon name={item.name} className="text-xl shrink-0 opacity-90" />
                        <span className="truncate">{item.name}</span>
                      </p>
                      {item.quantity && (
                        <span className={`shrink-0 px-2 py-1 rounded-lg text-xs font-black border-2 ${
                          item.checked 
                            ? "bg-muted text-muted-foreground border-transparent" 
                            : "bg-primary/10 text-primary border-primary/20"
                        }`}>
                          {item.quantity}
                        </span>
                      )}
                    </div>
                  </div>
                  <button 
                    onClick={() => removeCustomItem(item.id)}
                    className="p-2 text-muted-foreground hover:text-destructive transition-colors"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Dialog to Add to Pantry */}
      <Dialog open={!!addingItem} onOpenChange={(open) => !open && setAddingItem(null)}>
        <DialogContent className="max-w-[90vw] w-[400px] rounded-2xl">
          <DialogHeader>
            <DialogTitle>Item Comprado</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Item</label>
              <Input value={addingItem?.name || ""} disabled className="bg-muted text-foreground" />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Quantidade para despensa</label>
              <Input 
                value={purchaseQuantity} 
                onChange={(e) => setPurchaseQuantity(e.target.value)} 
                placeholder="Ex: 500g, 2L, 1 unidade" 
              />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Validade (Opcional)</label>
              <Input 
                type="date"
                value={purchaseExpiry} 
                onChange={(e) => setPurchaseExpiry(e.target.value)} 
              />
            </div>
          </div>
          <div className="flex flex-col gap-2">
            <Button 
              onClick={handleAddToPantry} 
              disabled={isSubmitting}
              className="w-full bg-primary text-white font-bold rounded-xl h-11"
            >
              {isSubmitting ? "Adicionando..." : "Adicionar à Despensa"}
            </Button>
            <Button 
              onClick={handleJustCheck} 
              variant="outline"
              disabled={isSubmitting}
              className="w-full font-bold rounded-xl h-11"
            >
              Apenas Riscar da Lista
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Dialog for Adding Manual Item */}
      <Dialog open={isAddManualOpen} onOpenChange={setIsAddManualOpen}>
        <DialogContent className="max-w-[90vw] w-[400px] rounded-2xl">
          <DialogHeader>
            <DialogTitle>Novo Item na Lista</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Nome do Produto <span className="text-destructive">*</span></label>
              <Input 
                value={manualName} 
                onChange={(e) => setManualName(e.target.value)} 
                placeholder="Ex: Arroz, Ovos, Detergente..." 
                autoFocus
              />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Quantidade (Opcional)</label>
              <Input 
                value={manualQty} 
                onChange={(e) => setManualQty(e.target.value)} 
                placeholder="Ex: 5kg, 2L, 1 unidade" 
              />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Validade (Opcional)</label>
              <Input 
                type="date"
                value={manualExpiry} 
                onChange={(e) => setManualExpiry(e.target.value)} 
              />
            </div>
          </div>
          <div className="flex flex-col gap-2">
            <Button 
              onClick={handleSaveManualItem} 
              disabled={!manualName.trim()} 
              className="w-full bg-primary text-white font-bold rounded-xl h-11"
            >
              Adicionar à Lista
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
