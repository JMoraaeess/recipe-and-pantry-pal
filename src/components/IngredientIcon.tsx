import { useState, useEffect } from "react";
import { getIngredientEmoji } from "@/lib/emoji";
import { supabase } from "@/integrations/supabase/client";

interface IngredientIconProps {
  name: string;
  className?: string; // allow overriding classes
}

export function IngredientIcon({ name, className = "" }: IngredientIconProps) {
  const [icon, setIcon] = useState<string>("🥘");

  useEffect(() => {
    if (!name) return;

    // 1. Mapeamento estático local hiper-rápido (Offline Priority)
    const localEmoji = getIngredientEmoji(name);
    if (localEmoji) {
      setIcon(localEmoji);
      return;
    }

    // 2. Cache local das buscas anteriores na IA
    const cacheKey = `emoji-cache-${name.toLowerCase().trim()}`;
    const cached = localStorage.getItem(cacheKey);
    if (cached) {
      setIcon(cached);
      return;
    }

    // 3. Fallback visual no paint inicial (se inédito)
    setIcon("🥘");

    // 4. Conectar em background à Edge Function `get-emoji` (se Online)
    if (!navigator.onLine) return;

    let isMounted = true;
    const fetchAI = async () => {
      try {
        const { data, error } = await supabase.functions.invoke("get-emoji", {
          body: { ingredient: name }
        });

        if (error) throw error;
        
        if (data?.emoji && isMounted) {
          setIcon(data.emoji);
          localStorage.setItem(cacheKey, data.emoji);
        }
      } catch (err) {
        console.warn("Falha na chamada da IA para buscar ícone:", err);
      }
    };

    fetchAI();

    return () => {
      isMounted = false;
    };
  }, [name]);

  return <span className={`inline-flex items-center justify-center font-emoji ${className}`}>{icon}</span>;
}
