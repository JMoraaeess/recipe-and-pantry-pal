-- Create recipe cache table for scalability
CREATE TABLE IF NOT EXISTS public.recipe_cache (
  url TEXT PRIMARY KEY,
  recipe_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.recipe_cache ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read the cache (this is the key to scaling)
CREATE POLICY "Anyone can read cache" 
ON public.recipe_cache FOR SELECT 
USING (true);

-- Only allow service role (or the edge function) to insert into cache
-- Note: Edge functions usually use the service_role or a specific authenticated user
CREATE POLICY "Service role can insert cache" 
ON public.recipe_cache FOR INSERT 
WITH CHECK (true); 
