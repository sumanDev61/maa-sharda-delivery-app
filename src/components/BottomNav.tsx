import React from 'react';
import { Home, Receipt, Wallet, User } from 'lucide-react';

interface BottomNavProps {
  currentIndex: number;
  onSelect: (index: number) => void;
  activeOrdersCount?: number;
}

export const BottomNav: React.FC<BottomNavProps> = ({
  currentIndex,
  onSelect,
  activeOrdersCount = 0,
}) => {
  const tabs = [
    { label: 'Home', icon: Home },
    { label: 'Orders', icon: Receipt, badge: activeOrdersCount > 0 ? activeOrdersCount : undefined },
    { label: 'Earnings', icon: Wallet },
    { label: 'Profile', icon: User },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 bg-slate-950/95 backdrop-blur-md border-t border-slate-800 max-w-md mx-auto shadow-2xl">
      <div className="grid grid-cols-4 h-14 px-2">
        {tabs.map((tab, idx) => {
          const Icon = tab.icon;
          const isActive = currentIndex === idx;
          return (
            <button
              key={tab.label}
              onClick={() => onSelect(idx)}
              className={`flex flex-col items-center justify-center gap-0.5 transition-all h-full cursor-pointer relative ${
                isActive ? 'text-[#00E676]' : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              <div className="relative">
                <div
                  className={`p-0.5 rounded-lg transition-all ${
                    isActive ? 'bg-emerald-500/20 text-[#00E676]' : ''
                  }`}
                >
                  <Icon className={`w-4 h-4 transition-transform ${isActive ? 'scale-105 stroke-[2.5]' : 'stroke-2'}`} />
                </div>
                {tab.badge && (
                  <span className="absolute -top-1 -right-2 min-w-3.5 h-3.5 px-0.5 rounded-full bg-rose-500 text-white text-[8px] font-black flex items-center justify-center shadow-sm">
                    {tab.badge}
                  </span>
                )}
              </div>
              <span className={`text-[9px] font-bold tracking-tight transition-colors ${isActive ? 'text-white font-extrabold' : 'text-slate-400'}`}>
                {tab.label}
              </span>
              {isActive && (
                <span className="absolute bottom-0.5 w-1 h-1 rounded-full bg-[#00E676]" />
              )}
            </button>
          );
        })}
      </div>
    </nav>
  );
};
