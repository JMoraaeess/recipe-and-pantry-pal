import { useState, useEffect } from "react";

/**
 * Hook para buscar o ícone de um ingrediente.
 * Retorna sempre o ícone padrão de garfo e faca cruzados, conforme solicitado.
 */
export function useIngredientIcon(_name: string) {
  const [iconName, setIconName] = useState<string>("🍽️");

  useEffect(() => {
    setIconName("🍽️");
  }, [_name]);

  return iconName;
}
