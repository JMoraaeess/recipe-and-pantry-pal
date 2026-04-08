-- Add expiry_date column to pantry_items table
ALTER TABLE public.pantry_items 
ADD COLUMN IF NOT EXISTS expiry_date DATE;
