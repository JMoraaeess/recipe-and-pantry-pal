import { UtensilsCrossed } from "lucide-react";

interface IngredientIconProps {
  name?: string; 
  className?: string;
  size?: number;
}

export function IngredientIcon({ className = "", size = 20 }: IngredientIconProps) {
  return (
    <span
      className={`inline-flex items-center justify-center ${className}`}
      aria-hidden="true"
    >
      <UtensilsCrossed
        size={size}
        strokeWidth={1.5}
        className="text-muted-foreground"
      />
    </span>
  );
}
