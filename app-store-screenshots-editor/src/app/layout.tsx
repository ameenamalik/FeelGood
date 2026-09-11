import type { Metadata } from "next";
import localFont from "next/font/local";
import "./globals.css";

// FeelGood's one-font rule: SF Pro Rounded everywhere, no exceptions.
// Bold rather than Black — Black read as too heavy to comfortably read.
const font = localFont({ src: "../fonts/SF-Pro-Rounded-Bold.otf", weight: "700" });

export const metadata: Metadata = {
  title: "App Store Screenshots",
  description: "Design and export App Store + Google Play screenshots.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={font.className}>{children}</body>
    </html>
  );
}
