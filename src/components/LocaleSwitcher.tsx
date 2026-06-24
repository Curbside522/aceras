"use client";

import { useLocale } from "next-intl";
import { useRouter, usePathname } from "@/i18n/navigation";

export default function LocaleSwitcher() {
  const locale = useLocale();
  const router = useRouter();
  const pathname = usePathname();

  function toggle() {
    const next = locale === "es" ? "en" : "es";
    router.replace(pathname, { locale: next });
  }

  return (
    <button
      onClick={toggle}
      className="flex items-center rounded-full border border-gray-300 text-sm font-medium overflow-hidden"
      aria-label={locale === "es" ? "Switch to English" : "Cambiar a Español"}
    >
      <span
        className={`px-3 py-1 transition-colors ${
          locale === "es"
            ? "bg-gray-900 text-white"
            : "bg-transparent text-gray-600"
        }`}
      >
        ES
      </span>
      <span
        className={`px-3 py-1 transition-colors ${
          locale === "en"
            ? "bg-gray-900 text-white"
            : "bg-transparent text-gray-600"
        }`}
      >
        EN
      </span>
    </button>
  );
}
