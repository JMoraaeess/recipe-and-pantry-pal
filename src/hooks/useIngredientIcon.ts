import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";

/**
 * Hook para buscar o nome do ícone Lucide para um ingrediente via Gemini AI.
 * Fluxo: Cache Local (localStorage) -> Gemini AI (get-emoji Edge Function)
 */
export function useIngredientIcon(name: string) {
  const [iconName, setIconName] = useState<string>("ChefHat");

  useEffect(() => {
    if (!name) return;

    // 1. Cache local
    const cacheKey = `icon-ai-${name.toLowerCase().trim()}`;
    const cached = localStorage.getItem(cacheKey);
    if (cached) {
      setIconName(cached);
      return;
    }

    // 2. Buscar na IA em background
    if (!navigator.onLine) return;

    let isMounted = true;
    const fetchAI = async () => {
      try {
        const { data, error } = await supabase.functions.invoke("get-emoji", {
          body: { ingredient: name },
        });

        if (error) throw error;

        const icon = data?.icon || "ChefHat";
        if (isMounted) {
          setIconName(icon);
          localStorage.setItem(cacheKey, icon);
        }
      } catch (err) {
        console.warn("Falha ao buscar ícone para:", name, err);
      }
    };

    fetchAI();
    return () => { isMounted = false; };
  }, [name]);

  return iconName;
}
