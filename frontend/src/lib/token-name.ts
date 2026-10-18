/** Sama dengan server (`create_token`): trim, lalu 1..=100 code point (bukan unit UTF-16). */
export const TOKEN_NAME_MAX = 100;

export function validateTokenName(raw: string): string | null {
  const length = Array.from(raw.trim()).length;
  if (length === 0) return "Nama token wajib diisi";
  if (length > TOKEN_NAME_MAX) return `Nama token maksimal ${TOKEN_NAME_MAX} karakter`;
  return null;
}
