Present code changes outside-in:
- Usage examples: reveal the API shape and ergonomics
- Signatures: confirm types and options
- Flow: show where it fits in calling code

Example - adding a `formatCurrency` utility:

```ts
// 1. USAGE - how callers will use it
const price = formatCurrency(1999, 'USD');  // "$19.99"
const euro = formatCurrency(1999, 'EUR');   // "€19.99"

// 2. SIGNATURE - the contract
function formatCurrency(cents: number, currency: CurrencyCode): string

type CurrencyCode = 'USD' | 'EUR' | 'GBP';

// 3. FLOW - where it's called from
// src/components/ProductCard.tsx:45-49
export function ProductCard({ product }: Props) {
  const store = useStore();
  return (
    <span className="price">{formatCurrency(product.priceInCents, store.currency)}</span>
    //                       ^^^^^^^^^^^^^^^ line 48: new call site
  );
}
```
