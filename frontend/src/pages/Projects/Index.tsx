import { Head, router } from "@inertiajs/react";
import { LogOut } from "lucide-react";
import { Logo } from "@/components/logo";
import { ThemeToggle } from "@/components/theme-toggle";
import { Button } from "@/components/ui/button";
import type { ProjectsIndexProps } from "@/types/generated/ProjectsIndexProps";
import type { SharedProps } from "@/types/generated/SharedProps";

// Stub pemilih Project (Task 11): header + judul + daftar sederhana. Kartu, dialog Add Project,
// dan menu akun dilengkapi Task 17.
export default function ProjectsIndex({ projects, auth }: ProjectsIndexProps & SharedProps) {
  return (
    <div className="min-h-svh">
      <Head title="Projects" />
      <header className="flex h-14 items-center justify-between gap-4 border-b border-border bg-card px-4 md:px-8">
        <Logo className="text-[20px]" />
        <div className="flex items-center gap-3">
          <ThemeToggle />
          <Button
            variant="outline"
            className="size-11 bg-transparent px-0 md:h-9 md:w-auto md:px-4 dark:bg-transparent"
            onClick={() => router.post("/logout")}
          >
            <LogOut aria-hidden="true" />
            <span className="sr-only md:not-sr-only">Logout</span>
          </Button>
        </div>
      </header>
      <main className="mx-auto flex max-w-7xl flex-col gap-6 px-4 pt-4 pb-8 md:px-8 md:pt-12 md:pb-16">
        <div className="flex flex-col gap-1.5">
          <h1 className="text-[28px] tracking-[-0.03em]">Projects</h1>
          <p className="text-[15px] text-muted-foreground">Pilih project untuk mulai bekerja.</p>
        </div>
        {auth && (
          <p className="text-sm text-muted-foreground">
            Masuk sebagai <span className="font-semibold text-foreground">{auth.user.displayName}</span>
          </p>
        )}
        {projects.length === 0 ? (
          <p className="text-sm text-muted-foreground">Belum ada project.</p>
        ) : (
          <ul className="grid grid-cols-1 gap-4 md:grid-cols-[repeat(auto-fill,minmax(240px,1fr))] md:gap-6">
            {projects.map((p) => (
              <li key={p.slug} className="rounded-xl border border-border bg-card p-4 md:p-6">
                <span className="font-semibold">{p.name}</span>
                <span className="block font-mono text-[13px] text-muted-foreground">/p/{p.slug}</span>
              </li>
            ))}
          </ul>
        )}
      </main>
    </div>
  );
}
