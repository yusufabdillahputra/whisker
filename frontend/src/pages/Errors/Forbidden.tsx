import { ErrorPage } from "@/components/error-page";
import type { ErrorPageProps } from "@/types/generated/ErrorPageProps";
import type { SharedProps } from "@/types/generated/SharedProps";

export default function Forbidden({ status }: ErrorPageProps & SharedProps) {
  return (
    <ErrorPage status={status} title="Akses ditolak" description="Akun Anda tidak punya akses ke halaman ini." />
  );
}
