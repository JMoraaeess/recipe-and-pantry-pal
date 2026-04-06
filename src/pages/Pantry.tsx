import { useState, useEffect } from "react";
import { getPantry, addPantryItem, removePantryItem, type PantryItem } from "@/lib/supabaseStore";
import { formatQuantity } from "@/lib/units";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Plus, X, Apple } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

export default function Pantry() {
  const { toast } = useToast();
  const [pantry, setPantry] = useState<PantryItem[]>([]);
  const [name, setName] = useState("");
  const [quantity, setQuantity] = useState("");
  const [loading, setLoading] = useState(true);

  const load = async () => {
    try {
      setPantry(await getPantry());
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    try {
      await addPantryItem({ name: name.trim(), quantity: quantity.trim() || undefined });
      await load();
      setName("");
      setQuantity("");
      toast({ title: "Adicionado!", description: `${name.trim()} está na sua despensa.` });
    } catch (err: any) {
      toast({ title: "Erro", description: err.message, variant: "destructive" });
    }
  };

  const handleRemove = async (id: string) => {
    await removePantryItem(id);
    load();
  };

  return (
    <div className="min-h-screen pb-20">
      <header className="px-5 pt-8 pb-4">
        <h1 className="text-3xl font-bold tracking-tight">Minha Despensa</h1>
        <p className="text-muted-foreground mt-1">O que você tem em casa</p>
      </header>

      <form onSubmit={handleAdd} className="px-5 flex gap-2 mb-6">
        <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="Nome do alimento" className="flex-1" />
        <Input value={quantity} onChange={(e) => setQuantity(e.target.value)} placeholder="Ex: 2kg" className="w-24" />
        <Button type="submit" size="icon" className="shrink-0"><Plus className="h-4 w-4" /></Button>
      </form>

      <div className="px-5">
        {loading ? (
          <p className="text-center py-20 text-muted-foreground">Carregando...</p>
        ) : pantry.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <div className="h-20 w-20 rounded-full bg-muted flex items-center justify-center mb-4">
              <Apple className="h-10 w-10 text-muted-foreground" />
            </div>
            <p className="text-muted-foreground text-lg">Sua despensa está vazia</p>
            <p className="text-muted-foreground text-sm mt-1">Adicione os alimentos que você tem em casa</p>
          </div>
        ) : (
          <div className="space-y-2">
            {pantry.map((item) => {
              const available = item.numericValue != null ? item.numericValue - (item.reservedValue || 0) : null;
              const hasReservation = (item.reservedValue || 0) > 0;
              const baseUnit = item.unit || "g";
              return (
                <div key={item.id} className="flex items-center gap-3 bg-card border border-border rounded-xl px-4 py-3">
                  <div className="flex-1">
                    <p className="font-medium">{item.name}</p>
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      {item.numericValue != null ? (
                        <>
                          <span>Total: {formatQuantity(item.numericValue, baseUnit)}</span>
                          {hasReservation && (
                            <>
                              <span>·</span>
                              <span className="text-accent-foreground">Reservado: {formatQuantity(item.reservedValue || 0, baseUnit)}</span>
                              <span>·</span>
                              <span className="font-medium text-secondary">Livre: {formatQuantity(Math.max(0, available || 0), baseUnit)}</span>
                            </>
                          )}
                        </>
                      ) : item.quantity ? (
                        <span>{item.quantity}</span>
                      ) : null}
                    </div>
                  </div>
                  <button onClick={() => handleRemove(item.id)} className="p-2 text-muted-foreground hover:text-destructive transition-colors">
                    <X className="h-4 w-4" />
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
