import { Button } from "@/components/ui/button";
import { formatDateTime } from "@/lib/format-date";
import type { TokenRow } from "@/types/generated/TokenRow";

const STATUS: Record<TokenRow["status"], { label: string; className: string }> = {
  active: { label: "Aktif", className: "bg-badge-green text-badge-green-foreground" },
  revoked: { label: "Revoked", className: "bg-badge-gray text-badge-gray-foreground" },
};

export function TokenTable({ tokens, onRevoke }: { tokens: TokenRow[]; onRevoke: (token: TokenRow) => void }) {
  if (tokens.length === 0) {
    return <p className="text-sm text-muted-foreground">Belum ada token.</p>;
  }
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[640px] text-left text-sm">
        <thead className="text-[13px] text-muted-foreground">
          <tr className="border-b border-border">
            <th scope="col" className="py-2 pr-4 font-semibold">Nama</th>
            <th scope="col" className="py-2 pr-4 font-semibold">Prefix</th>
            <th scope="col" className="py-2 pr-4 font-semibold">Dibuat</th>
            <th scope="col" className="py-2 pr-4 font-semibold">Terakhir dipakai</th>
            <th scope="col" className="py-2 pr-4 font-semibold">Status</th>
            <th scope="col" className="relative py-2 font-semibold"><span className="sr-only">Aksi</span></th>
          </tr>
        </thead>
        <tbody>
          {tokens.map((t) => {
            const status = STATUS[t.status];
            return (
              <tr key={t.id} className="border-b border-border last:border-0">
                <th scope="row" className="py-3 pr-4 font-medium break-words">{t.name}</th>
                <td className="py-3 pr-4 font-mono text-[13px]">{t.displayPrefix}</td>
                <td className="py-3 pr-4 whitespace-nowrap">{formatDateTime(t.createdAt)}</td>
                <td className="py-3 pr-4 whitespace-nowrap">
                  {t.lastUsedAt ? formatDateTime(t.lastUsedAt) : <span className="text-muted-foreground">Belum pernah</span>}
                </td>
                <td className="py-3 pr-4">
                  <span className={`inline-flex h-6 items-center rounded-full px-2.5 text-xs font-semibold ${status.className}`}>
                    {status.label}
                  </span>
                </td>
                <td className="py-3 text-right">
                  {t.status === "active" && (
                    <Button
                      type="button"
                      variant="outline"
                      aria-label={`Revoke ${t.name}`}
                      onClick={() => onRevoke(t)}
                      className="h-11 md:h-9"
                    >
                      Revoke
                    </Button>
                  )}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
