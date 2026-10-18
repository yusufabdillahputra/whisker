import { Head, Link } from "@inertiajs/react";
import { Logo } from "@/components/logo";
import { ThemeToggle } from "@/components/theme-toggle";
import { Button } from "@/components/ui/button";

interface ErrorPageProps {
  status: number;
  title: string;
  description: string;
}

/** Pola halaman error (DESIGN.md §12): mark, kode status, judul Sora, deskripsi, tombol sekunder. */
export function ErrorPage({ status, title, description }: ErrorPageProps) {
  return (
    <div className="flex min-h-svh flex-col">
      <Head title={title} />
      <div className="flex justify-end p-4 md:px-8">
        <ThemeToggle />
      </div>
      <main className="flex flex-1 flex-col items-center justify-center gap-6 px-4 pb-16 text-center">
        <Logo variant="mark" className="h-[58px] w-[60px]" />
        <div className="flex flex-col gap-1.5">
          <p className="font-mono text-[13px] text-muted-foreground">{status}</p>
          <h1 className="text-[28px] tracking-[-0.03em]">{title}</h1>
          <p className="max-w-md text-[15px] text-muted-foreground">{description}</p>
        </div>
        <Button asChild variant="outline" className="h-11 bg-transparent px-4 md:h-9 dark:bg-transparent">
          <Link href="/">Kembali ke Projects</Link>
        </Button>
      </main>
    </div>
  );
}
