import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { addPantryItem } from "@/lib/supabaseStore";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ArrowLeft, Apple, Plus, Loader2 } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

export default function AddPantryItem() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [name, setName] = useState("");
  const [quantity, setQuantity] = useState("");
  const [expiryDate, setExpiryDate] = useState("");
  const [saving, setSaving] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    
    setSaving(true);
    try {
      await addPantryItem({ 
        name: name.trim(), 
        quantity: quantity.trim() || undefined,
        expiryDate: expiryDate || undefined
      });
      toast({ 
        title: "Item adicionado!", 
        description: `${name.trim()} foi adicionado à sua despensa.` 
      });
      navigate("/pantry");
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Algo deu errado.";
      toast({ 
        title: "Erro ao adicionar", 
        description: message, 
        variant: "destructive" 
      });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="min-h-screen bg-background pb-20">
      <header className="px-5 pt-6 pb-4">
        <Button 
          variant="ghost" 
          size="sm" 
          onClick={() => navigate(-1)} 
          className="gap-1 -ml-2 mb-2 text-muted-foreground"
        >
          <ArrowLeft className="h-4 w-4" /> Voltar
        </Button>
        <h1 className="text-3xl font-bold tracking-tight">Novo Item</h1>
        <p className="text-muted-foreground mt-1">O que você comprou para a despensa?</p>
      </header>

      <div className="px-5 mt-4">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="bg-card rounded-2xl p-6 border border-border shadow-sm space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-medium text-foreground">Nome do Alimento</label>
              <div className="relative">
                <Apple className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input 
                  value={name} 
                  onChange={(e) => setName(e.target.value)} 
                  placeholder="Ex: Arroz, Feijão, Farinha..." 
                  className="pl-9 h-11"
                  autoFocus
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium text-foreground">Quantidade</label>
              <Input 
                value={quantity} 
                onChange={(e) => setQuantity(e.target.value)} 
                placeholder="Ex: 2kg, 500g, 2 latas..." 
                className="h-11"
              />
              <p className="text-[10px] text-muted-foreground italic">
                Dica: Use unidades como kg, g, ml, l ou unidades (latas, caixas).
              </p>
            </div>

            <div className="space-y-2 pt-2">
              <label className="text-sm font-medium text-foreground flex items-center gap-2">
                Data de Validade <span className="text-[10px] text-muted-foreground font-normal">(Opcional)</span>
              </label>
              <Input 
                type="date"
                value={expiryDate} 
                onChange={(e) => setExpiryDate(e.target.value)} 
                className="h-11"
              />
            </div>
          </div>

          <Button 
            type="submit" 
            className="w-full h-12 text-lg font-semibold gap-2" 
            disabled={!name.trim() || saving}
          >
            {saving ? (
              <Loader2 className="h-5 w-5 animate-spin" />
            ) : (
              <Plus className="h-5 w-5" />
            )}
            Adicionar à Despensa
          </Button>
        </form>
      </div>
    </div>
  );
}
