import { Copy } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";

/** Salin `text` ke clipboard + toast. Dipakai Tokens (Task 15) dan panel Sambungkan AI Client (Task 19). */
export function CopyButton({
  text,
  label,
  successMessage = "Token disalin",
}: {
  text: string;
  label: string;
  successMessage?: string;
}) {
  async function copy() {
    try {
      await navigator.clipboard.writeText(text);
      toast.success(successMessage);
    } catch {
      toast.error("Gagal menyalin. Salin manual dari kotak.");
    }
  }
  return (
    <Button type="button" variant="outline" onClick={copy} className="h-11 md:h-9">
      <Copy aria-hidden="true" />
      {label}
    </Button>
  );
}
