// Mapeia os tokens para o Tailwind: use bg-surface, text-muted, rounded-md... nunca hex direto.
// Importar replica/design/tokens.css no layout raiz do app.
import type { Config } from 'tailwindcss'

export default {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        'bg': 'var(--color-bg)',
        'surface': 'var(--color-surface)',
        'surface-raised': 'var(--color-surface-raised)',
        'border': 'var(--color-border)',
        'border-input': 'var(--color-border-input)',
        'text': 'var(--color-text)',
        'text-muted': 'var(--color-text-muted)',
        'accent': 'var(--color-accent)',
        'accent-hover': 'var(--color-accent-hover)',
        'accent-soft': 'var(--color-accent-soft)',
        'on-accent': 'var(--color-on-accent)',
        'focus': 'var(--color-focus)',
        'danger': 'var(--color-danger)',
        'danger-soft': 'var(--color-danger-soft)',
        'success': 'var(--color-success)',
        'success-soft': 'var(--color-success-soft)',
        'warning': 'var(--color-warning)',
        'warning-soft': 'var(--color-warning-soft)',
        'bubble-in': 'var(--color-bubble-in)',
        'bubble-out': 'var(--color-bubble-out)',
        'on-bubble-out': 'var(--color-on-bubble-out)'
      },
      fontFamily: { sans: 'var(--font-sans)', mono: 'var(--font-mono)' },
      fontSize: {
        xs: ['var(--text-xs)', { lineHeight: 'var(--leading-xs)', fontWeight: 'var(--weight-xs)' }],
        sm: ['var(--text-sm)', { lineHeight: 'var(--leading-sm)', fontWeight: 'var(--weight-sm)' }],
        base: ['var(--text-base)', { lineHeight: 'var(--leading-base)', fontWeight: 'var(--weight-base)' }],
        lg: ['var(--text-lg)', { lineHeight: 'var(--leading-lg)', fontWeight: 'var(--weight-lg)' }],
        xl: ['var(--text-xl)', { lineHeight: 'var(--leading-xl)', fontWeight: 'var(--weight-xl)' }],
        display: ['var(--text-display)', { lineHeight: 'var(--leading-display)', fontWeight: 'var(--weight-display)' }]
      },
      spacing: {
        '0': 'var(--space-0)',
        '1': 'var(--space-1)',
        '2': 'var(--space-2)',
        '3': 'var(--space-3)',
        '4': 'var(--space-4)',
        '6': 'var(--space-5)',
        '8': 'var(--space-6)',
        '12': 'var(--space-7)',
        '16': 'var(--space-8)'
      },
      borderRadius: {
        sm: 'var(--radius-sm)',
        md: 'var(--radius-md)',
        lg: 'var(--radius-lg)',
        bubble: 'var(--radius-bubble)',
        pill: 'var(--radius-pill)'
      },
      boxShadow: { card: 'var(--shadow-card)', pop: 'var(--shadow-pop)' },
      maxWidth: { content: 'var(--layout-max-content)' },
      minHeight: { tap: 'var(--layout-tap-target-min)' },
      minWidth: { tap: 'var(--layout-tap-target-min)' },
    },
  },
} satisfies Config
