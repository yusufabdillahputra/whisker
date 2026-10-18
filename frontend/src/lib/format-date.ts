const FORMAT = new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" });

/** Timestamp RFC 3339 UTC dari server → tanggal+jam di zona waktu browser. */
export function formatDateTime(iso: string): string {
  const date = new Date(iso);
  return Number.isNaN(date.getTime()) ? iso : FORMAT.format(date);
}
