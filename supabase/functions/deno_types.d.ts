/**
 * Arquivo de tipos para o VS Code resolver as importações do Deno
 */
declare module "std/server" {
  export function serve(handler: (req: any) => Promise<any> | any): void;
}
declare module "std/server_legacy" {
  export function serve(handler: (req: any) => Promise<any> | any): void;
}
