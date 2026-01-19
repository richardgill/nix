Present code changes outside-in, showing new code **in context** with surrounding existing code:

1. **Usage & Signature** - reveal the API shape, types, and ergonomics
2. **Flow** - show where new code lands relative to existing code

Example - adding a `formatCurrency` utility:

```ts
// Usage
function formatCurrency(cents: number, currency: 'USD' | 'EUR' | 'GBP'): string

formatCurrency(1999, 'USD');  // "$19.99"
formatCurrency(1999, 'EUR');  // "€19.99"

// Flow - where it lands in existing code
// src/components/ProductCard.tsx
export function ProductCard({ product }: Props) {
  const store = useStore();                          // existing
  const price = formatCurrency(product.cents, ...);  // ← new

  return (
    <div className="card">                           {/* existing */}
      <span className="price">{price}</span>         {/* ← new */}
      <span className="name">{product.name}</span>   {/* existing */}
    </div>
  );
}
```

The reviewer should see what already exists around the new code, not just the new code in isolation.
