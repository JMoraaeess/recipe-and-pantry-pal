import { Home, BookOpen, Apple, ShoppingCart } from "lucide-react";
import { NavLink, useLocation } from "react-router-dom";

const tabs = [
  { to: "/recipes", icon: BookOpen, label: "Receitas" },
  { to: "/shopping-list", icon: ShoppingCart, label: "Compras" },
  { to: "/pantry", icon: Apple, label: "Despensa" },
];

export function BottomNav() {
  const location = useLocation();
  if (location.pathname === "/auth") return null;

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-background border-t border-border z-50">
      <div className="flex justify-around items-center h-16 max-w-lg mx-auto">
        {tabs.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end
            className={({ isActive }) =>
              `flex flex-col items-center gap-1 px-4 py-2 rounded-lg transition-colors ${
                isActive
                  ? "text-primary"
                  : "text-muted-foreground hover:text-foreground"
              }`
            }
          >
            <Icon className="h-5 w-5" />
            <span className="text-xs font-medium">{label}</span>
          </NavLink>
        ))}
      </div>
    </nav>
  );
}
