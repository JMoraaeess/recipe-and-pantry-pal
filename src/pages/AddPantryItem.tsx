import { useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { addPantryItem } from "@/lib/supabaseStore";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ArrowLeft, Apple, Plus, Loader2, ScanBarcode, X } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { Html5Qrcode } from "html5-qrcode";
import { useEffect, useRef } from "react";

export default function AddPantryItem() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const location = useLocation();
  const [name, setName] = useState("");
  const [quantity, setQuantity] = useState("");
  const [category, setCategory] = useState(location.state?.category || "Mercearia");
  const [expiryDate, setExpiryDate] = useState("");
  const [saving, setSaving] = useState(false);
  const [showScanner, setShowScanner] = useState(false);
  const scannerRef = useRef<Html5Qrcode | null>(null);

  const startScanner = async () => {
    setShowScanner(true);
    setTimeout(async () => {
      try {
        const html5QrCode = new Html5Qrcode("barcode-scanner-box");
        scannerRef.current = html5QrCode;
        await html5QrCode.start(
          { facingMode: "environment" },
          {
            fps: 10,
            qrbox: { width: 250, height: 150 },
          },
          (decodedText) => {
            console.log("Barcode scanned:", decodedText);
            stopScanner();
            lookupBarcode(decodedText);
          },
          (errorMessage) => {
            // Ignore errors while searching
          }
        );
      } catch (err) {
        console.error("Scanner error:", err);
        toast({ title: "Erro na câmera", description: "Não foi possível abrir a câmera.", variant: "destructive" });
        setShowScanner(false);
      }
    }, 100);
  };

  const stopScanner = async () => {
    if (scannerRef.current) {
      try {
        await scannerRef.current.stop();
        scannerRef.current = null;
      } catch (e) {}
    }
    setShowScanner(false);
  };

  const lookupBarcode = async (barcode: string) => {
    toast({ title: "Buscando produto...", description: `Código: ${barcode}` });
    try {
      const resp = await fetch(`https://world.openfoodfacts.org/api/v0/product/${barcode}.json`);
      const data = await resp.json();
      if (data.status === 1) {
        const product = data.product;
        const productName = product.product_name_pt || product.product_name || "";
        setName(productName);
        
        // Tentativa simples de mapear categoria
        const tags = product.categories_tags || [];
        if (tags.some((t: string) => t.includes("beverage"))) setCategory("Bebidas");
        else if (tags.some((t: string) => t.includes("dairy"))) setCategory("Laticínios");
        else if (tags.some((t: string) => t.includes("meat"))) setCategory("Proteínas");
        else if (tags.some((t: string) => t.includes("vegetable"))) setCategory("Hortifruti");
        
        toast({ title: "Produto encontrado!", description: productName });
      } else {
        toast({ title: "Não encontrado", description: "Produto não cadastrado na base.", variant: "destructive" });
      }
    } catch (e) {
      toast({ title: "Erro na busca", description: "Falha ao consultar base de dados.", variant: "destructive" });
    }
  };

  useEffect(() => {
    return () => {
      if (scannerRef.current) scannerRef.current.stop().catch(e => {});
    };
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    
    setSaving(true);
    try {
      await addPantryItem({ 
        name: name.trim(), 
        quantity: quantity.trim() || undefined,
        category: category,
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
        {showScanner ? (
          <div className="bg-card rounded-2xl p-4 border border-border shadow-sm mb-6 relative overflow-hidden">
            <Button 
              variant="ghost" 
              size="icon" 
              className="absolute top-2 right-2 z-10 bg-background/50 backdrop-blur"
              onClick={stopScanner}
            >
              <X className="h-4 w-4" />
            </Button>
            <div id="barcode-scanner-box" className="w-full aspect-[4/3] rounded-xl overflow-hidden bg-black">
            </div>
            <p className="text-center text-xs text-muted-foreground mt-3">Alinhe o código de barras no centro</p>
          </div>
        ) : (
          <Button 
            variant="outline" 
            onClick={startScanner} 
            className="w-full mb-6 py-8 flex flex-col gap-2 rounded-2xl border-dashed border-primary/40 hover:bg-primary/5 hover:border-primary transition-all"
          >
            <ScanBarcode className="h-8 w-8 text-primary" />
            <div className="text-center">
              <p className="font-bold text-sm">Escanear Código de Barras</p>
              <p className="text-[10px] text-muted-foreground">Cadastre produtos instantaneamente</p>
            </div>
          </Button>
        )}

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
                  autoFocus={!showScanner}
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

            <div className="space-y-2">
              <label className="text-sm font-medium text-foreground block mb-2">Categoria *</label>
              <div className="grid grid-cols-2 gap-2">
                {["Proteínas", "Frios", "Hortifruti", "Laticínios", "Mercearia", "Bebidas", "Temperos"].map((cat) => (
                  <Button
                    key={cat}
                    type="button"
                    variant={category === cat ? "default" : "outline"}
                    onClick={() => setCategory(cat)}
                    size="sm"
                    className="h-10 text-xs truncate"
                  >
                    {cat}
                  </Button>
                ))}
              </div>
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
