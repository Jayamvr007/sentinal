import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Sentinel | Real-Time Market Watchdog",
  description: "Monitor markets in real-time with custom alerts and cross-platform sync. Built with FastAPI, Next.js, and SwiftUI.",
  keywords: ["trading", "market", "stocks", "alerts", "real-time", "dashboard"],
  authors: [{ name: "Sentinel" }],
  openGraph: {
    title: "Sentinel | Real-Time Market Watchdog",
    description: "Monitor markets in real-time with custom alerts and cross-platform sync.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} antialiased`}>
        {children}
      </body>
    </html>
  );
}

