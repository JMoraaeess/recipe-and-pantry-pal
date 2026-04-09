import { Utensils } from "lucide-react";

interface IngredientIconProps {
  name?: string; // Kept for prop compatibility but unused now
  className?: string;
  size?: number;
}

export function IngredientIcon({ className = "", size = 20 }: IngredientIconProps) {
  return (
    <span
      className={`inline-flex items-center justify-center ${className}`}
      aria-hidden="true"
    >
      <Utensils
        size={size}
        strokeWidth={1.5}
        className="text-muted-foreground"
      />
    </span>
  );
}
