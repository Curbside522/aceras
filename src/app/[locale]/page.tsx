import { useTranslations } from "next-intl";
import LocaleSwitcher from "@/components/LocaleSwitcher";

export default function Home() {
  const t = useTranslations("Home");

  return (
    <div className="min-h-screen flex flex-col">
      <header className="flex items-center justify-between px-6 py-4">
        <span className="text-lg font-bold tracking-tight">Aceras</span>
        <LocaleSwitcher />
      </header>
      <main className="flex flex-1 items-center justify-center">
        <h1 className="text-4xl font-bold">{t("greeting")}</h1>
      </main>
    </div>
  );
}
