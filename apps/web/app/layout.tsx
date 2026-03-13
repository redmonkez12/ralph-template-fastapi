import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Ralph Monorepo",
  description: "Minimal Next.js + FastAPI starter powered by bun, turbo, and uv.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
