import { router, useForm } from "@inertiajs/react";
import { type FormEvent, useEffect, useState } from "react";
import { toast } from "sonner";
import { CopyButton } from "@/components/copy-button";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { CreatedTokenAlert } from "@/features/tokens/created-token-alert";
import { TokenTable } from "@/features/tokens/token-table";
import { AccountLayout } from "@/layouts/account-layout";
import { validateTokenName } from "@/lib/token-name";
import type { AccountTokensProps } from "@/types/generated/AccountTokensProps";
import type { CreatedToken } from "@/types/generated/CreatedToken";
import type { CreateTokenForm } from "@/types/generated/CreateTokenForm";
import type { SharedProps } from "@/types/generated/SharedProps";
import type { TokenRow } from "@/types/generated/TokenRow";

type Props = AccountTokensProps & SharedProps & { errors?: Partial<Record<keyof CreateTokenForm, string>> };

const MCP_JSON = `{
  "mcpServers": {
    "whisker": {
      "type": "http",
      "url": "http://127.0.0.1:8080/mcp",
      "headers": { "Authorization": "Bearer \${WHISKER_TOKEN}" }
    }
  }
}`;

export default function Tokens({ tokens, createdToken, errors = {} }: Props) {
  const form = useForm<CreateTokenForm>({ name: "" });
  const [clientError, setClientError] = useState<string | null>(null);
  // Token polos hanya di memori komponen; props page langsung dibersihkan (lihat efek di bawah).
  const [shown, setShown] = useState<CreatedToken | null>(createdToken);

  useEffect(() => {
    if (!createdToken) return;
    setShown(createdToken);
    // Entri riwayat tidak boleh menyimpan token polos: ganti props entri aktif tanpa `plain`.
    router.replace({
      props: (current) => ({ ...current, createdToken: null }),
      preserveScroll: true,
      preserveState: true,
    });
  }, [createdToken]);

  const nameError = clientError ?? errors.name;

  function submit(e: FormEvent) {
    e.preventDefault();
    const invalid = validateTokenName(form.data.name);
    setClientError(invalid);
    if (invalid) return;
    form.post("/account/tokens", {
      // Respons 200 me-render halaman (bukan redirect); benar tanpa bergantung pada `onSuccess`.
      preserveState: "errors",
      preserveScroll: true,
      replace: true,
      onSuccess: () => {
        form.reset();
      },
    });
  }

  function revoke(token: TokenRow) {
    router.post(`/account/tokens/${token.id}/revoke`, {}, {
      preserveScroll: true,
      onSuccess: () => {
        toast.success(`Token ${token.name} direvoke.`);
      },
    });
  }

  return (
    <AccountLayout section="tokens" title="Tokens">
      <section
        aria-labelledby="tokens-title"
        className="flex flex-col gap-4 rounded-xl border border-border bg-card p-4 text-card-foreground md:gap-6 md:p-6"
      >
        <div className="flex flex-col gap-1.5">
          <h2 id="tokens-title" className="text-xl tracking-[-0.02em]">
            Tokens
          </h2>
          <p className="text-sm text-muted-foreground">
            Personal Access Token untuk AI client yang terhubung ke endpoint MCP Whisker.
          </p>
        </div>

        {shown && <CreatedTokenAlert token={shown} onDismiss={() => setShown(null)} />}

        <form onSubmit={submit} noValidate className="flex flex-col gap-4 md:flex-row md:items-end">
          <div className="flex flex-1 flex-col gap-1.5">
            <Label htmlFor="name" className="font-semibold">
              Nama token
            </Label>
            <Input
              id="name"
              autoComplete="off"
              required
              value={form.data.name}
              onChange={(e) => {
                form.setData("name", e.target.value);
                setClientError(null);
              }}
              aria-invalid={nameError ? true : undefined}
              aria-describedby={nameError ? "name-error" : undefined}
              placeholder="mis. Laptop kerja"
              className="h-11 bg-background text-base md:h-9 md:text-sm dark:bg-background"
            />
            {nameError && (
              <p id="name-error" role="alert" className="text-[13px] text-destructive">
                {nameError}
              </p>
            )}
          </div>
          <Button
            type="submit"
            disabled={form.processing}
            className="h-11 w-full text-[15px] font-semibold md:h-9 md:w-auto md:text-sm"
          >
            Buat token
          </Button>
        </form>

        <TokenTable tokens={tokens} onRevoke={revoke} />
      </section>

      <section
        aria-labelledby="connect-title"
        className="flex flex-col gap-3 rounded-xl border border-border bg-card p-4 text-card-foreground md:p-6"
      >
        <h2 id="connect-title" className="text-xl tracking-[-0.02em]">
          Sambungkan AI client
        </h2>
        <p className="text-sm text-muted-foreground">
          Simpan token di variabel lingkungan <code className="font-mono">WHISKER_TOKEN</code>, lalu taruh ini di{" "}
          <code className="font-mono">.mcp.json</code> proyek Anda. Jangan tempel token mentah ke berkas konfigurasi.
        </p>
        <pre className="overflow-x-auto rounded-md bg-code p-3 font-mono text-[13px] text-code-foreground">{MCP_JSON}</pre>
        <div>
          <CopyButton text={MCP_JSON} label="Salin konfigurasi" successMessage="Konfigurasi disalin" />
        </div>
      </section>
    </AccountLayout>
  );
}
