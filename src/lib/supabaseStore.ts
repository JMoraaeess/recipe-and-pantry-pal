import { supabase } from "@/integrations/supabase/client";
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
  numericValue?: number;
  unit?: string;
  reservedValue?: number;
}

// ---- Recipes ----

export async function getRecipes(): Promise<Recipe[]> {
  const { data, error } = await supabase
    .from("recipes")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) throw error;
  return (data || []).map((r: any) => ({
    id: r.id,
    title: r.title,
    description: r.description || "",
    ingredients: (r.ingredients as Ingredient[]) || [],
    instructions: r.instructions || "",
    source: r.source || undefined,
    status: r.status || "nova",
    createdAt: r.created_at,
  }));
}

export async function saveRecipe(recipe: Omit<Recipe, "id">) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Not authenticated");

  const { error } = await supabase.from("recipes").insert({
    user_id: user.id,
    title: recipe.title,
    description: recipe.description,
    ingredients: recipe.ingredients as any,
    instructions: recipe.instructions,
    source: recipe.source || null,
    status: recipe.status,
  });
  if (error) throw error;
}

export async function updateRecipe(recipe: Recipe) {
  const { error } = await supabase
    .from("recipes")
    .update({
      title: recipe.title,
      description: recipe.description,
      ingredients: recipe.ingredients as any,
      instructions: recipe.instructions,
      source: recipe.source || null,
      status: recipe.status,
    })
    .eq("id", recipe.id);
  if (error) throw error;
}

export async function deleteRecipe(id: string) {
  const recipes = await getRecipes();
  const recipe = recipes.find((r) => r.id === id);
  if (recipe?.status === "reservada") {
    await unreserveIngredients(recipe);
  }
  const { error } = await supabase.from("recipes").delete().eq("id", id);
  if (error) throw error;
}

// ---- Pantry ----

export async function getPantry(): Promise<PantryItem[]> {
  const { data, error } = await supabase
    .from("pantry_items")
    .select("*")
    .order("created_at", { ascending: true });

  if (error) throw error;
  return (data || []).map((p: any) => ({
    id: p.id,
    name: p.name,
    quantity: p.quantity || undefined,
    numericValue: p.numeric_value ?? undefined,
    unit: p.unit || undefined,
    reservedValue: p.reserved_value ?? 0,
  }));
}

export async function addPantryItem(item: { name: string; quantity?: string }) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Not authenticated");

  let numericValue: number | undefined;
  let unit: string | undefined;

  if (item.quantity) {
    const parsed = parseQuantity(item.quantity);
    if (parsed) {
      numericValue = toBase(parsed);
      unit = parsed.category === "weight" ? "g" : parsed.category === "volume" ? "ml" : parsed.normalizedUnit;
    }
  }

  const { error } = await supabase.from("pantry_items").insert({
    user_id: user.id,
    name: item.name,
    quantity: item.quantity || null,
    numeric_value: numericValue ?? null,
    unit: unit || null,
  });
  if (error) throw error;
}

export async function removePantryItem(id: string) {
  const { error } = await supabase.from("pantry_items").delete().eq("id", id);
  if (error) throw error;
}

export async function updatePantryItemDb(item: PantryItem) {
  const { error } = await supabase
    .from("pantry_items")
    .update({
      name: item.name,
      quantity: item.quantity || null,
      numeric_value: item.numericValue ?? null,
      unit: item.unit || null,
      reserved_value: item.reservedValue ?? 0,
    })
    .eq("id", item.id);
  if (error) throw error;
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

export async function reserveIngredients(recipe: Recipe): Promise<{ success: boolean; missing: string[] }> {
  const pantry = await getPantry();
  const missing: string[] = [];

  for (const ing of recipe.ingredients) {
    const pantryItem = findPantryMatch(ing.name, pantry);
    if (!pantryItem) { missing.push(ing.name); continue; }

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
    if (!result.sufficient) { missing.push(ing.name); continue; }

    const recipeBaseValue = pantryItem.numericValue - result.remaining;
    pantryItem.reservedValue = (pantryItem.reservedValue || 0) + recipeBaseValue;
    await updatePantryItemDb(pantryItem);
  }

  return { success: missing.length === 0, missing };
}

export async function unreserveIngredients(recipe: Recipe) {
  const pantry = await getPantry();

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
    await updatePantryItemDb(pantryItem);
  }
}

export async function completeRecipe(recipe: Recipe): Promise<{ success: boolean; missing: string[] }> {
  const pantry = await getPantry();
  const missing: string[] = [];

  if (recipe.status === "reservada") {
    await unreserveIngredients(recipe);
  }

  // Re-fetch after unreserve
  const freshPantry = await getPantry();

  for (const ing of recipe.ingredients) {
    const pantryItem = findPantryMatch(ing.name, freshPantry);
    if (!pantryItem) { missing.push(ing.name); continue; }

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

    if (pantryItem.numericValue <= 0) {
      await removePantryItem(pantryItem.id);
    } else {
      await updatePantryItemDb(pantryItem);
    }
  }

  return { success: missing.length === 0, missing };
}

// ---- Check ingredients (for display) ----

export function checkIngredients(ingredients: Ingredient[], pantry: PantryItem[]) {
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

    return { ...ing, inPantry, sufficient, availableDisplay };
  });
}
