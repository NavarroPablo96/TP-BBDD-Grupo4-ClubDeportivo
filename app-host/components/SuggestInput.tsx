import type { Option } from "@/lib/types";

type Props = {
  id: string;
  type?: string;
  step?: number;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  options?: Option[];
};

const INPUT_CLASS =
  "mt-1 w-full rounded-md border border-line bg-white px-2 py-1.5 text-sm text-foreground outline-none focus:border-brand focus:ring-2 focus:ring-brand/20";

/**
 * Campo de texto con sugerencias (`datalist`): ofrece los valores válidos pero deja escribir
 * cualquier otro, para poder probar los rechazos de la base.
 */
export function SuggestInput({ id, type = "text", step, value, onChange, placeholder, options = [] }: Props) {
  const listId = options.length > 0 ? `${id}-list` : undefined;
  return (
    <>
      <input
        type={type}
        step={step}
        list={listId}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        autoComplete="off"
        className={INPUT_CLASS}
      />
      {listId && (
        <datalist id={listId}>
          {options.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </datalist>
      )}
    </>
  );
}
