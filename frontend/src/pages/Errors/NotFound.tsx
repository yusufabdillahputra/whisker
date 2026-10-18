import { ErrorPage } from "@/components/error-page";
import type { ErrorPageProps } from "@/types/generated/ErrorPageProps";
import type { SharedProps } from "@/types/generated/SharedProps";

export default function NotFound({ status }: ErrorPageProps & SharedProps) {
  return (
    <ErrorPage
      status={status}
      title="Halaman tidak ditemukan"
      description="Alamat yang Anda buka tidak ada atau sudah dipindahkan."
    />
  );
}
