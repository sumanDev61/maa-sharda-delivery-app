import React from 'react';

interface PrimaryButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  label: string;
  isLoading?: boolean;
  leading?: React.ReactNode;
  variant?: 'primary' | 'danger' | 'outline' | 'secondary';
}

export const PrimaryButton: React.FC<PrimaryButtonProps> = ({
  label,
  isLoading = false,
  leading,
  variant = 'primary',
  className = '',
  disabled,
  ...props
}) => {
  const baseClasses =
    'h-13 w-full rounded-2xl font-bold text-base flex items-center justify-center transition-all duration-200 active:scale-[0.99] disabled:opacity-50 disabled:cursor-not-allowed disabled:active:scale-100 shadow-sm';

  const variants = {
    primary: 'bg-[#00E676] hover:bg-[#00c864] text-slate-900 shadow-emerald-500/20',
    danger: 'bg-red-500 hover:bg-red-600 text-white shadow-red-500/20',
    outline: 'border-2 border-slate-200 dark:border-slate-700 bg-transparent text-slate-800 dark:text-slate-100 hover:bg-slate-100/50',
    secondary: 'bg-slate-800 hover:bg-slate-700 text-white',
  };

  return (
    <button
      disabled={disabled || isLoading}
      className={`${baseClasses} ${variants[variant]} ${className}`}
      {...props}
    >
      {isLoading ? (
        <div className="w-5 h-5 border-2 border-current border-t-transparent rounded-full animate-spin" />
      ) : (
        <span className="flex items-center justify-center gap-2">
          {leading}
          <span>{label}</span>
        </span>
      )}
    </button>
  );
};
