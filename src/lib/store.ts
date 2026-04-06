import { parseQuantity, toBase, subtractQuantity, formatQuantity, type ParsedQuantity } from "./units";

export interface Ingredient {
  name: string;
  quantity: string;
}

export type RecipeStatus = "nova" | "reservada" | "concluida";

export interface Recipe {
  id: string;
  title: string;
  description: string;
  ingredients: Ingredient[];
  instructions: string;
  source?: string;
  status: RecipeStatus;
  createdAt: string;
}

export interface PantryItem {
  id: string;
  name: string;
  quantity?: string;
  // Structured quantity for calculations
  numericValue?: number;
  unit?: string;
  // Amount reserved by recipes
  reservedValue?: number;
}

const RECIPES_KEY = "recipes";
const PANTRY_KEY = "pantry";

// ---- Recipes ----

export function getRecipes(): Recipe[] {
  const data = localStorage.getItem(RECIPES_KEY);
  const recipes = data ? JSON.parse(data) : [];
  // Migration: add status if missing
  return recipes.map((r: any) => ({ ...r, status: r.status || "nova" }));
}

function saveRecipes(recipes: Recipe[]) {
  localStorage.setItem(RECIPES_KEY, JSON.stringify(recipes));
}

export function saveRecipe(recipe: Recipe) {
  const recipes = getRecipes();
  recipes.unshift(recipe);
  saveRecipes(recipes);
}

export function updateRecipe(updated: Recipe) {
  const recipes = getRecipes().map((r) => (r.id === updated.id ? updated : r));
  saveRecipes(recipes);
}

export function deleteRecipe(id: string) {
  // Unreserve ingredients first
  const recipe = getRecipes().find((r) => r.id === id);
  if (recipe?.status === "reservada") {
    unreserveIngredients(recipe);
  }
  const recipes = getRecipes().filter((r) => r.id !== id);
  saveRecipes(recipes);
}

// ---- Pantry ----

export function getPantry(): PantryItem[] {
  const data = localStorage.getItem(PANTRY_KEY);
  return data ? JSON.parse(data) : [];
}

function savePantry(pantry: PantryItem[]) {
  localStorage.setItem(PANTRY_KEY, JSON.stringify(pantry));
}

export function addPantryItem(item: PantryItem) {
  // Parse numeric value and unit from quantity string
  if (item.quantity) {
    const parsed = parseQuantity(item.quantity);
    if (parsed) {
      item.numericValue = toBase(parsed);
      item.unit = parsed.category === "weight" ? "g" : parsed.category === "volume" ? "ml" : parsed.normalizedUnit;
    }
  }
  const pantry = getPantry();
  pantry.push(item);
  savePantry(pantry);
}

export function removePantryItem(id: string) {
  const pantry = getPantry().filter((i) => i.id !== id);
  savePantry(pantry);
}

export function updatePantryItem(updated: PantryItem) {
  const pantry = getPantry().map((i) => (i.id === updated.id ? updated : i));
  savePantry(pantry);
}

// ---- Ingredient matching ----

function normalizeIngredientName(name: string): string {
  return name
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .trim();
}

export function findPantryMatch(ingredientName: string, pantry: PantryItem[]): PantryItem | undefined {
  const normName = normalizeIngredientName(ingredientName);
  return pantry.find((p) => {
    const normPantry = normalizeIngredientName(p.name);
    return normPantry.includes(normName) || normName.includes(normPantry);
  });
}

// ---- Reserve / Complete ----

export function reserveIngredients(recipe: Recipe): { success: boolean; missing: string[] } {
  const pantry = getPantry();
  const missing: string[] = [];

  for (const ing of recipe.ingredients) {
    const pantryItem = findPantryMatch(ing.name, pantry);
    if (!pantryItem) {
      missing.push(ing.name);
      continue;
    }

    const recipeQty = parseQuantity(ing.quantity);
    if (!recipeQty || !pantryItem.numericValue) {
      // Can't calculate, just mark as matched
      continue;
    }

    const pantryQty: ParsedQuantity = {
      value: pantryItem.numericValue,
      unit: pantryItem.unit || "g",
      normalizedUnit: pantryItem.unit || "g",
      category: pantryItem.unit === "g" ? "weight" : pantryItem.unit === "ml" ? "volume" : "unit",
    };

    const result = subtractQuantity(pantryQty, recipeQty, ing.name);
    if (!result) {
      // Can't convert units, skip
      continue;
    }

    if (!result.sufficient) {
      missing.push(ing.name);
      continue;
    }

    // Add to reserved
    const recipeBaseValue = pantryItem.numericValue - result.remaining;
    pantryItem.reservedValue = (pantryItem.reservedValue || 0) + recipeBaseValue;
  }

  savePantry(pantry);
  return { success: missing.length === 0, missing };
}

export function unreserveIngredients(recipe: Recipe) {
  const pantry = getPantry();

  for (const ing of recipe.ingredients) {
    const pantryItem = findPantryMatch(ing.name, pantry);
    if (!pantryItem || !pantryItem.numericValue) continue;

    const recipeQty = parseQuantity(ing.quantity);
    if (!recipeQty) continue;

    const pantryQty: ParsedQuantity = {
      value: pantryItem.numericValue,
      unit: pantryItem.unit || "g",
      normalizedUnit: pantryItem.unit || "g",
      category: pantryItem.unit === "g" ? "weight" : pantryItem.unit === "ml" ? "volume" : "unit",
    };

    const result = subtractQuantity(pantryQty, recipeQty, ing.name);
    if (!result) continue;

    const recipeBaseValue = pantryItem.numericValue - result.remaining;
    pantryItem.reservedValue = Math.max(0, (pantryItem.reservedValue || 0) - recipeBaseValue);
  }

  savePantry(pantry);
}

export function completeRecipe(recipe: Recipe): { success: boolean; missing: string[] } {
  const pantry = getPantry();
  const missing: string[] = [];

  // If was reserved, remove reservation first
  if (recipe.status === "reservada") {
    unreserveIngredients(recipe);
  }

  // Subtract from pantry
  for (const ing of recipe.ingredients) {
    const pantryItem = findPantryMatch(ing.name, pantry);
    if (!pantryItem) {
      missing.push(ing.name);
      continue;
    }

    const recipeQty = parseQuantity(ing.quantity);
    if (!recipeQty || !pantryItem.numericValue) continue;

    const pantryQty: ParsedQuantity = {
      value: pantryItem.numericValue,
      unit: pantryItem.unit || "g",
      normalizedUnit: pantryItem.unit || "g",
      category: pantryItem.unit === "g" ? "weight" : pantryItem.unit === "ml" ? "volume" : "unit",
    };

    const result = subtractQuantity(pantryQty, recipeQty, ing.name);
    if (!result) continue;

    pantryItem.numericValue = Math.max(0, result.remaining);
    pantryItem.quantity = formatQuantity(pantryItem.numericValue, result.pantryBaseUnit);

    // Remove item if depleted
    if (pantryItem.numericValue <= 0) {
      const idx = pantry.indexOf(pantryItem);
      if (idx >= 0) pantry.splice(idx, 1);
    }
  }

  savePantry(pantry);
  return { success: missing.length === 0, missing };
}

// ---- Check ingredients (for display) ----

export function checkIngredients(
  ingredients: Ingredient[],
  pantry: PantryItem[]
) {
  return ingredients.map((ing) => {
    const match = findPantryMatch(ing.name, pantry);
    const inPantry = !!match;
    let sufficient = false;
    let availableDisplay = "";

    if (match && match.numericValue != null) {
      const recipeQty = parseQuantity(ing.quantity);
      if (recipeQty) {
        const pantryQty: ParsedQuantity = {
          value: match.numericValue,
          unit: match.unit || "g",
          normalizedUnit: match.unit || "g",
          category: match.unit === "g" ? "weight" : match.unit === "ml" ? "volume" : "unit",
        };
        const result = subtractQuantity(pantryQty, recipeQty, ing.name);
        if (result) {
          const available = match.numericValue - (match.reservedValue || 0);
          sufficient = available >= (match.numericValue - result.remaining);
          availableDisplay = formatQuantity(available, result.pantryBaseUnit);
        }
      } else {
        sufficient = true;
      }
    } else if (inPantry) {
      sufficient = true;
    }

    return {
      ...ing,
      inPantry,
      sufficient,
      availableDisplay,
    };
  });
}
