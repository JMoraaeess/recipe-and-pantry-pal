# Meu Cozinheiro — Documentação Completa

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Arquitetura do Projeto](#arquitetura-do-projeto)
3. [Estrutura de Arquivos](#estrutura-de-arquivos)
4. [Banco de Dados (Lovable Cloud)](#banco-de-dados)
5. [Autenticação](#autenticação)
6. [Funcionalidades Principais](#funcionalidades-principais)
7. [Sistema de Unidades e Conversão](#sistema-de-unidades)
8. [Edge Functions (Backend)](#edge-functions)
9. [Design System](#design-system)
10. [Guia de Deploy — App Nativo (Capacitor)](#guia-de-deploy)
11. [Configuração de Ambiente](#configuração-de-ambiente)
12. [Dependências Principais](#dependências-principais)

---

## 1. Visão Geral

**Meu Cozinheiro** é um app de gestão de receitas e despensa. Permite:
- Cadastrar receitas manualmente ou importar via IA (links de sites e YouTube)
- Gerenciar despensa com quantidades e unidades inteligentes
- Reservar ingredientes da despensa para receitas
- Concluir receitas e subtrair ingredientes automaticamente
- Verificar o que falta comprar para cada receita

**Stack:** React 18 + TypeScript + Vite 5 + Tailwind CSS + Lovable Cloud (Supabase)

---

## 2. Arquitetura do Projeto

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  React SPA  │────▶│  Lovable Cloud   │────▶│  PostgreSQL DB  │
│  (Frontend) │     │  (Supabase SDK)  │     │  (RLS habilitado)│
└─────────────┘     └──────────────────┘     └─────────────────┘
       │                     │
       │              ┌──────┴──────┐
       │              │ Edge Function│
       │              │ extract-recipe│
       │              │ (Deno + AI)  │
       │              └─────────────┘
       │
┌──────┴──────────┐
│  Capacitor      │
│  (iOS/Android)  │
└─────────────────┘
```

- **Frontend**: React SPA com roteamento via React Router
- **Backend**: Lovable Cloud com banco PostgreSQL + Row Level Security
- **IA**: Edge Function que usa Lovable AI (Gemini) para extrair receitas de URLs
- **Mobile**: Capacitor para empacotar como app nativo iOS/Android

---

## 3. Estrutura de Arquivos

```
src/
├── App.tsx                    # Roteamento principal e providers
├── main.tsx                   # Ponto de entrada
├── index.css                  # Design tokens (cores, fontes)
├── components/
│   ├── BottomNav.tsx          # Navegação inferior (3 tabs)
│   ├── NavLink.tsx            # Componente de link de navegação
│   └── ui/                   # Componentes shadcn/ui (button, input, etc.)
├── contexts/
│   └── AuthContext.tsx        # Provider de autenticação
├── hooks/
│   ├── use-mobile.tsx         # Detecção de mobile
│   └── use-toast.ts           # Hook de notificações
├── integrations/
│   └── supabase/
│       ├── client.ts          # Cliente Supabase (auto-gerado)
│       └── types.ts           # Tipos do banco (auto-gerado)
├── lib/
│   ├── store.ts               # Store local (localStorage, legado)
│   ├── supabaseStore.ts       # Store principal (Supabase)
│   ├── units.ts               # Sistema de conversão de unidades
│   └── utils.ts               # Utilitários (cn)
└── pages/
    ├── Auth.tsx               # Tela de login/cadastro
    ├── Recipes.tsx            # Lista de receitas
    ├── AddRecipe.tsx          # Adicionar receita (manual + IA)
    ├── RecipeDetail.tsx       # Detalhes + reservar/concluir
    ├── Pantry.tsx             # Gestão da despensa
    ├── Index.tsx              # Redirect
    └── NotFound.tsx           # Página 404

supabase/
├── config.toml                # Configuração do projeto
└── functions/
    └── extract-recipe/
        └── index.ts           # Edge Function de extração de receitas

capacitor.config.ts            # Configuração do Capacitor (iOS/Android)
```

---

## 4. Banco de Dados

### Tabelas

#### `recipes`
| Coluna       | Tipo      | Descrição                           |
|-------------|-----------|-------------------------------------|
| id          | uuid (PK) | ID único                            |
| user_id     | uuid      | Referência ao usuário               |
| title       | text      | Nome da receita                     |
| description | text      | Descrição curta                     |
| ingredients | jsonb     | Array de {name, quantity}           |
| instructions| text      | Modo de preparo                     |
| source      | text      | URL ou fonte da receita             |
| status      | text      | "nova", "reservada" ou "concluida"  |
| created_at  | timestamp | Data de criação                     |

#### `pantry_items`
| Coluna         | Tipo      | Descrição                                |
|---------------|-----------|------------------------------------------|
| id            | uuid (PK) | ID único                                 |
| user_id       | uuid      | Referência ao usuário                    |
| name          | text      | Nome do alimento                         |
| quantity      | text      | Quantidade original (ex: "2kg")          |
| numeric_value | numeric   | Valor convertido para unidade base (g/ml)|
| unit          | text      | Unidade base ("g" ou "ml")               |
| reserved_value| numeric   | Quantidade reservada por receitas        |
| created_at    | timestamp | Data de criação                          |

#### `profiles`
| Coluna       | Tipo      | Descrição            |
|-------------|-----------|----------------------|
| id          | uuid (PK) | Mesmo ID do auth.users|
| display_name| text      | Nome de exibição     |
| avatar_url  | text      | URL do avatar        |
| created_at  | timestamp | Data de criação      |

### Segurança (RLS)
Todas as tabelas possuem Row Level Security habilitado. Cada usuário acessa **somente** seus próprios dados, filtrados pelo `user_id`.

---

## 5. Autenticação

- **Método**: Email + senha (via Lovable Cloud Auth)
- **Fluxo**: Cadastro → Verificação por email → Login
- **Contexto React**: `AuthContext` fornece `user`, `session`, `loading` e `signOut`
- **Proteção de rotas**: `ProtectedRoute` redireciona para `/auth` se não autenticado
- **Persistência**: Sessão gerenciada automaticamente pelo SDK

---

## 6. Funcionalidades Principais

### 6.1 Receitas
- **Listar**: Página principal mostra todas as receitas do usuário
- **Adicionar manualmente**: Formulário com título, descrição, ingredientes e modo de preparo
- **Importar via IA**: Cola um link (site ou YouTube) e a IA extrai a receita automaticamente
- **Status**: Nova → Reservada → Concluída

### 6.2 Despensa
- **Adicionar itens**: Nome + quantidade (ex: "farinha", "2kg")
- **Conversão automática**: "2kg" é convertido para 2000g internamente
- **Visualização**: Mostra total, reservado e livre para cada item

### 6.3 Reserva de Ingredientes
- Ao "Reservar" uma receita, o sistema verifica a despensa
- Ingredientes disponíveis têm quantidade reservada (não disponível para outras receitas)
- Mostra o que falta comprar (badge vermelho)

### 6.4 Conclusão de Receita
- Ao "Concluir", os ingredientes são efetivamente **subtraídos** da despensa
- Itens zerados são removidos automaticamente

### 6.5 Importação via IA
- **Edge Function** `extract-recipe` processa URLs de sites e YouTube
- Para YouTube: extrai título, descrição e legendas/transcrição
- Usa modelo **Gemini 3 Flash** via Lovable AI
- Retorna receita estruturada em JSON

---

## 7. Sistema de Unidades (`src/lib/units.ts`)

### Unidades Suportadas

| Categoria | Unidades                                                    |
|-----------|-------------------------------------------------------------|
| Peso      | kg, g, mg, quilos, gramas                                   |
| Volume    | l, ml, xícara, colher de sopa, colher de chá, copo          |
| Unidade   | unidade, dente, fatia, pedaço, pitada, a gosto              |

### Conversão
- Peso é convertido para **gramas** (base)
- Volume é convertido para **mililitros** (base)
- Conversão peso↔volume usa tabela de **densidade** para ingredientes comuns (açúcar, farinha, leite, óleo, etc.)

### Frações Suportadas
- Numéricas: `1/2`, `1 e 1/2`
- Textuais: `meia`, `meio`
- Unicode: `½`, `¼`, `¾`, `⅓`, `⅔`

---

## 8. Edge Functions

### `extract-recipe`
- **Caminho**: `supabase/functions/extract-recipe/index.ts`
- **Runtime**: Deno (deploy automático)
- **Entrada**: `{ url: string }`
- **Saída**: `{ recipe: { title, description, ingredients[], instructions } }`
- **IA**: Usa Lovable AI Gateway (`ai.gateway.lovable.dev`) com modelo Gemini
- **Suporte**: Sites de receitas e vídeos do YouTube

---

## 9. Design System

### Paleta de Cores (HSL)
| Token       | Light              | Uso                    |
|-------------|-------------------|------------------------|
| background  | 36 33% 97%        | Fundo geral (bege)     |
| foreground  | 24 10% 15%        | Texto principal        |
| primary     | 14 60% 52%        | Terracota (ações)      |
| secondary   | 140 20% 45%       | Verde sálvia           |
| accent      | 42 80% 60%        | Dourado (destaques)    |
| muted       | 36 20% 90%        | Elementos sutis        |

### Fontes
- **Display**: Playfair Display (títulos, h1-h3)
- **Body**: Inter (corpo do texto)

### Componentes
Usa **shadcn/ui** com customizações via Tailwind CSS e design tokens.

---

## 10. Guia de Deploy — App Nativo (Capacitor)

### Pré-requisitos
- **Node.js** 18+ e **npm**
- **Para iOS**: Mac com **Xcode** 15+ instalado
- **Para Android**: **Android Studio** com SDK configurado
- Conta de desenvolvedor Apple (para publicar na App Store)
- Conta de desenvolvedor Google (para publicar no Google Play)

### Passo a Passo

#### 1. Exportar o projeto para o GitHub
No Lovable, clique em **"Export to GitHub"** para criar o repositório.

#### 2. Clonar e instalar
```bash
git clone https://github.com/SEU-USUARIO/meu-cozinheiro.git
cd meu-cozinheiro
npm install
```

#### 3. Adicionar plataformas nativas
```bash
# Para iOS
npx cap add ios

# Para Android
npx cap add android
```

#### 4. Atualizar dependências nativas
```bash
npx cap update ios
npx cap update android
```

#### 5. Construir o projeto
```bash
npm run build
```

#### 6. Sincronizar com as plataformas nativas
```bash
npx cap sync
```

#### 7. Executar no emulador ou dispositivo
```bash
# iOS (requer Mac com Xcode)
npx cap run ios

# Android (requer Android Studio)
npx cap run android
```

#### 8. Abrir no IDE nativo para ajustes
```bash
npx cap open ios      # Abre no Xcode
npx cap open android  # Abre no Android Studio
```

### Para Publicação

#### iOS (App Store)
1. Abra o projeto no Xcode (`npx cap open ios`)
2. Configure o **Bundle ID**, **Team** e **Signing**
3. Em `capacitor.config.ts`, remova ou comente o bloco `server.url` para usar o build local
4. Faça `npm run build && npx cap sync`
5. No Xcode: Product → Archive → Distribute App

#### Android (Google Play)
1. Abra no Android Studio (`npx cap open android`)
2. Configure o `applicationId` no `build.gradle`
3. Em `capacitor.config.ts`, remova o bloco `server.url`
4. Faça `npm run build && npx cap sync`
5. Build → Generate Signed Bundle / APK

### ⚠️ Importante
- O `server.url` no `capacitor.config.ts` é apenas para **desenvolvimento** (hot-reload)
- Para **produção**, remova o bloco `server` inteiro para que o app use os arquivos locais
- Sempre rode `npx cap sync` após atualizar dependências ou fazer `git pull`

---

## 11. Configuração de Ambiente

### Variáveis de Ambiente (automáticas no Lovable)
- `VITE_SUPABASE_URL` — URL do backend
- `VITE_SUPABASE_PUBLISHABLE_KEY` — Chave pública do backend
- `LOVABLE_API_KEY` — Chave da API de IA (usada na Edge Function)

### Capacitor
- `appId`: `app.lovable.78dfa0569de64a36862a88c09d9a66f6`
- `appName`: `Meu Cozinheiro`
- `webDir`: `dist`

---

## 12. Dependências Principais

| Pacote                    | Versão  | Uso                              |
|--------------------------|---------|----------------------------------|
| react                    | 18.x    | Framework UI                     |
| react-router-dom         | 6.x     | Roteamento SPA                   |
| @supabase/supabase-js    | 2.x     | SDK do backend                   |
| @tanstack/react-query    | 5.x     | Cache e estado servidor          |
| @capacitor/core          | 7.x     | Bridge nativo                    |
| @capacitor/ios           | 7.x     | Plataforma iOS                   |
| @capacitor/android       | 7.x     | Plataforma Android               |
| tailwindcss              | 3.x     | Estilização                      |
| lucide-react             | 0.4x    | Ícones                           |
| vaul                     | 0.9.x   | Drawer bottom sheet              |
| sonner                   | 1.7.x   | Notificações toast               |
| zod                      | 3.x     | Validação de schemas             |

---

## 📖 Referências
- [Documentação Lovable](https://docs.lovable.dev/)
- [Capacitor Docs](https://capacitorjs.com/docs)
- [Guia Lovable + Mobile](https://lovable.dev/blog/lovable-mobile-app-development)
- [shadcn/ui](https://ui.shadcn.com/)
