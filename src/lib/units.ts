// Unit conversion system for Brazilian cooking measurements

export type UnitCategory = "weight" | "volume" | "unit";

export interface ParsedQuantity {
  value: number;
  unit: string;
  normalizedUnit: string;
  category: UnitCategory;
}

// Map common Brazilian cooking terms to normalized units
const UNIT_ALIASES: Record<string, string> = {
  // Weight
  "kg": "kg",
  "kilo": "kg",
  "kilos": "kg",
  "quilos": "kg",
  "quilo": "kg",
  "g": "g",
  "gramas": "g",
  "grama": "g",
  "gr": "g",
  "mg": "mg",

  // Volume  
  "l": "l",
  "litro": "l",
  "litros": "l",
  "ml": "ml",
  "mililitros": "ml",
  "mililitro": "ml",
  "xícara": "xicara",
  "xicara": "xicara",
  "xícaras": "xicara",
  "xicaras": "xicara",
  "xíc": "xicara",
  "xíc.": "xicara",
  "colher de sopa": "colher_sopa",
  "colheres de sopa": "colher_sopa",
  "colher (sopa)": "colher_sopa",
  "colher de chá": "colher_cha",
  "colheres de chá": "colher_cha",
  "colher (chá)": "colher_cha",
  "colher de café": "colher_cafe",
  "colheres de café": "colher_cafe",
  "copo": "copo",
  "copos": "copo",

  // Units
  "unidade": "un",
  "unidades": "un",
  "un": "un",
  "und": "un",
  "dente": "un",
  "dentes": "un",
  "fatia": "un",
  "fatias": "un",
  "pedaço": "un",
  "pedaços": "un",
  "pitada": "pitada",
  "pitadas": "pitada",
  "a gosto": "a_gosto",
};

const UNIT_CATEGORY: Record<string, UnitCategory> = {
  "kg": "weight",
  "g": "weight",
  "mg": "weight",
  "l": "volume",
  "ml": "volume",
  "xicara": "volume",
  "colher_sopa": "volume",
  "colher_cha": "volume",
  "colher_cafe": "volume",
  "copo": "volume",
  "un": "unit",
  "pitada": "unit",
  "a_gosto": "unit",
};

// Conversion factors to base unit (grams for weight, ml for volume)
const TO_BASE: Record<string, number> = {
  // Weight → grams
  "mg": 0.001,
  "g": 1,
  "kg": 1000,
  // Volume → ml
  "ml": 1,
  "l": 1000,
  "xicara": 240,       // 1 xícara (chá) ≈ 240ml
  "colher_sopa": 15,   // 1 colher de sopa ≈ 15ml
  "colher_cha": 5,     // 1 colher de chá ≈ 5ml
  "colher_cafe": 2.5,  // 1 colher de café ≈ 2.5ml
  "copo": 250,         // 1 copo americano ≈ 250ml
};

// Density approximations (g per ml) for common ingredients
// Used to convert between weight and volume
const INGREDIENT_DENSITY: Record<string, number> = {
  "açúcar": 0.85,
  "acucar": 0.85,
  "açúcar refinado": 0.85,
  "açúcar cristal": 0.85,
  "açúcar mascavo": 0.8,
  "açúcar de confeiteiro": 0.56,
  "farinha": 0.6,
  "farinha de trigo": 0.6,
  "farinha de rosca": 0.55,
  "farinha de mandioca": 0.55,
  "amido de milho": 0.5,
  "maizena": 0.5,
  "maisena": 0.5,
  "leite": 1.03,
  "água": 1.0,
  "óleo": 0.92,
  "azeite": 0.92,
  "manteiga": 0.91,
  "margarina": 0.91,
  "mel": 1.42,
  "sal": 1.2,
  "fermento": 0.7,
  "fermento em pó": 0.7,
  "chocolate em pó": 0.5,
  "cacau em pó": 0.5,
  "nescau": 0.5,
  "achocolatado": 0.5,
  "leite condensado": 1.3,
  "creme de leite": 1.0,
  "arroz": 0.75,
  "feijão": 0.8,
  "aveia": 0.4,
};

/**
 * Parse a quantity string like "2kg", "1 xícara (chá)", "3 colheres de sopa"
 */
export function parseQuantity(raw: string): ParsedQuantity | null {
  if (!raw || raw.trim() === "") return null;

  // Normalize accents for matching
  const text = raw
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .trim();

  // Handle "a gosto"
  if (text.includes("a gosto")) {
    return { value: 0, unit: "a gosto", normalizedUnit: "a_gosto", category: "unit" };
  }

  let value = 0;
  let unitPart = "";

  // Handle fractions and "meia"/"meio"
  let processedText = text
    .replace(/meia/g, "0.5")
    .replace(/meio/g, "0.5")
    .replace(/½/g, "0.5")
    .replace(/¼/g, "0.25")
    .replace(/¾/g, "0.75")
    .replace(/⅓/g, "0.333")
    .replace(/⅔/g, "0.667");

  // Match "1 e 1/2" or "1 1/2"
  const compoundMatch = processedText.match(/^(\d+(?:[.,]\d+)?)\s*(?:e\s+)?(\d+)\s*\/\s*(\d+)\s+(.+)/);
  if (compoundMatch) {
    value = parseFloat(compoundMatch[1].replace(",", ".")) + parseInt(compoundMatch[2]) / parseInt(compoundMatch[3]);
    unitPart = compoundMatch[4];
  } else {
    const fracMatch = processedText.match(/^(\d+)\s*\/\s*(\d+)\s+(.+)/);
    if (fracMatch) {
      value = parseInt(fracMatch[1]) / parseInt(fracMatch[2]);
      unitPart = fracMatch[3];
    } else {
      const simpleMatch = processedText.match(/^(\d+(?:[.,]\d+)?)\s*(.*)/);
      if (simpleMatch) {
        value = parseFloat(simpleMatch[1].replace(",", "."));
        unitPart = simpleMatch[2].trim();
      } else {
        return null;
      }
    }
  }

  if (value <= 0 && unitPart === "") return null;

  // Clean up unit part - handle (cha), (sopa), (cafe) after accent normalization
  unitPart = unitPart
    .replace(/\(cha\)/g, "de cha")
    .replace(/\(sopa\)/g, "de sopa")
    .replace(/\(cafe\)/g, "de cafe")
    .replace(/^de\s+/, "")
    .trim();

  // Build accent-normalized alias map
  const normalizeStr = (s: string) =>
    s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();

  let normalizedUnit = "un";
  let matchedAlias = "";
  const sortedAliases = Object.keys(UNIT_ALIASES).sort((a, b) => b.length - a.length);

  for (const alias of sortedAliases) {
    const normAlias = normalizeStr(alias);
    if (unitPart.startsWith(normAlias) || unitPart === normAlias) {
      normalizedUnit = UNIT_ALIASES[alias];
      matchedAlias = alias;
      break;
    }
  }

  const category = UNIT_CATEGORY[normalizedUnit] || "unit";

  return {
    value,
    unit: matchedAlias || unitPart || "un",
    normalizedUnit,
    category,
  };
}

/**
 * Convert a quantity to base units (grams or ml)
 */
export function toBase(qty: ParsedQuantity): number {
  const factor = TO_BASE[qty.normalizedUnit];
  if (factor == null) return qty.value;
  return qty.value * factor;
}

/**
 * Convert from base units back to a target unit
 */
export function fromBase(baseValue: number, targetUnit: string): number {
  const factor = TO_BASE[targetUnit];
  if (factor == null || factor === 0) return baseValue;
  return baseValue / factor;
}

/**
 * Try to convert between weight and volume using ingredient density
 */
function getDensity(ingredientName: string): number | null {
  const name = ingredientName.toLowerCase().trim();
  for (const [key, density] of Object.entries(INGREDIENT_DENSITY)) {
    if (name.includes(key) || key.includes(name)) {
      return density;
    }
  }
  return null;
}

/**
 * Check if we can subtract recipe ingredient from pantry item.
 * Returns the remaining amount in pantry base units, or null if incompatible.
 */
export function subtractQuantity(
  pantryQty: ParsedQuantity,
  recipeQty: ParsedQuantity,
  ingredientName: string
): { remaining: number; pantryBaseUnit: string; sufficient: boolean } | null {
  const pantryBase = toBase(pantryQty);
  let recipeBase = toBase(recipeQty);

  // Same category → direct subtraction
  if (pantryQty.category === recipeQty.category) {
    if (pantryQty.category === "unit") {
      return {
        remaining: pantryQty.value - recipeQty.value,
        pantryBaseUnit: pantryQty.normalizedUnit,
        sufficient: pantryQty.value >= recipeQty.value,
      };
    }
    return {
      remaining: pantryBase - recipeBase,
      pantryBaseUnit: pantryQty.category === "weight" ? "g" : "ml",
      sufficient: pantryBase >= recipeBase,
    };
  }

  // Cross-category (weight ↔ volume): use density
  const density = getDensity(ingredientName);
  if (density == null) return null; // Can't convert

  if (pantryQty.category === "weight" && recipeQty.category === "volume") {
    // Convert recipe volume (ml) to weight (g): g = ml * density
    const recipeGrams = recipeBase * density;
    return {
      remaining: pantryBase - recipeGrams,
      pantryBaseUnit: "g",
      sufficient: pantryBase >= recipeGrams,
    };
  }

  if (pantryQty.category === "volume" && recipeQty.category === "weight") {
    // Convert recipe weight (g) to volume (ml): ml = g / density
    const recipeMl = recipeBase / density;
    return {
      remaining: pantryBase - recipeMl,
      pantryBaseUnit: "ml",
      sufficient: pantryBase >= recipeMl,
    };
  }

  return null;
}

/**
 * Format a base value back to a friendly display string
 */
export function formatQuantity(value: number, baseUnit: string): string {
  if (baseUnit === "g") {
    if (value >= 1000) return `${(value / 1000).toFixed(2).replace(/\.?0+$/, "")} kg`;
    return `${Math.round(value)} g`;
  }
  if (baseUnit === "ml") {
    if (value >= 1000) return `${(value / 1000).toFixed(2).replace(/\.?0+$/, "")} L`;
    return `${Math.round(value)} ml`;
  }
  return `${value}`;
}
