import {
  Beef, Egg, Fish, Milk, Apple, Leaf, Coffee, Cookie,
  Pizza, Sandwich, Beer, Flame, Droplets, Cherry, ChefHat,
  Wheat, Grape, IceCream2, Carrot, Salad, Soup, Package,
  Banana, Nut, Citrus, CookingPot, Utensils,
} from "lucide-react";
import type { LucideProps } from "lucide-react";
import type { FC } from "react";

/** Catálogo curado de ícones Lucide outline para ingredientes */
export const INGREDIENT_ICONS: Record<string, FC<LucideProps>> = {
  Beef,
  Egg,
  Fish,
  Milk,
  Apple,
  Leaf,
  Coffee,
  Cookie,
  Pizza,
  Sandwich,
  Beer,
  Flame,
  Droplets,
  Cherry,
  ChefHat,
  Wheat,
  Grape,
  IceCream2,
  Carrot,
  Salad,
  Soup,
  Package,
  Banana,
  Nut,
  Citrus,
  CookingPot,
  Utensils,
};

export const ICON_NAMES = Object.keys(INGREDIENT_ICONS).join(", ");
export const DEFAULT_ICON = Utensils;
