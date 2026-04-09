/// <reference types="vite/client" />

declare module "https://deno.land/std@0.190.0/http/server.ts" {
  export function serve(handler: (req: any) => Promise<any> | any): void;
}

declare module "https://deno.land/std@0.168.0/http/server.ts" {
  export function serve(handler: (req: any) => Promise<any> | any): void;
}
