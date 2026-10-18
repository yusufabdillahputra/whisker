import { CopyButton } from "@/components/copy-button";
import type { CreatedToken } from "@/types/generated/CreatedToken";

/** Token polos tampil sekali. Nilainya hanya hidup di memori komponen. */
export function CreatedTokenAlert({ token, onDismiss }: { token: CreatedToken; onDismiss: () => void }) {
  return (
    <div
      role="status"
      data-testid="created-token"
      className="flex flex-col gap-3 rounded-lg border border-border bg-accent p-4 text-sm text-foreground"
    >
      <p>
        Token <strong>{token.name}</strong> dibuat. Salin sekarang; token ini tidak akan ditampilkan lagi.
      </p>
      <div className="flex flex-col gap-2 md:flex-row md:items-center">
        <code
          data-testid="created-token-value"
          className="min-w-0 flex-1 rounded-md bg-code px-3 py-2 font-mono text-[13px] break-all text-code-foreground"
        >
          {token.plain}
        </code>
        <CopyButton text={token.plain} label="Salin" />
      </div>
      <div>
        <button type="button" onClick={onDismiss} className="text-[13px] text-muted-foreground underline">
          Sembunyikan
        </button>
      </div>
    </div>
  );
}
