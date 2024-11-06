import clsx from "clsx";

import { pressStart, redhat } from "@/app/core/components/Fonts";
import { AppProvider } from "./core/hooks/AppProvider";

import "./app.css";
import "@rainbow-me/rainbowkit/styles.css";
import { Metadata } from "next";
import Script from "next/script";

function parseFeatureVar(feature: string | undefined): boolean {
  return feature === "true" ? true : false;
}

const features = {
  governancePage: parseFeatureVar(process.env.FEATURE_GOVERNANCE),
  breadCounter: parseFeatureVar(process.env.FEATURE_BREAD_COUNTER),
  recastVote: parseFeatureVar(process.env.FEATURE_RECAST_VOTE),
};

export type Features = {
  [K in keyof typeof features]: boolean;
};

export const metadata: Metadata = {
  metadataBase: new URL("https://app.breadchain.xyz/"),
};

export default function App({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <link rel="icon" type="image/svg+xml" href="/favicon.ico" />
      <link
        rel="apple-touch-icon"
        sizes="180x180"
        href="/apple-touch-icon.png"
      />
      <link
        rel="icon"
        type="image/png"
        sizes="32x32"
        href="/favicon-32x32.png"
      />
      <link
        rel="icon"
        type="image/png"
        sizes="16x16"
        href="/favicon-16x16.png"
      />
      <link rel="manifest" href="/manifest.json" />
      <link rel="mask-icon" href="/safari-pinned-tab.svg" color="#5bbad5" />
      <meta name="msapplication-TileColor" content="#da532c" />
      <meta name="theme-color" content="#ffffff" />

      <Script
        defer
        data-domain="app.breadchain.xyz"
        src="https://analytics.breadchain.xyz/js/script.tagged-events.outbound-links.js"
      />

      <body
        className={clsx(
          "relative bg-[#F0F0F0] dark:bg-breadgray-grey100 dark:text-breadgray-white",
          pressStart.variable,
          redhat.variable
        )}
      >
        <AppProvider features={features}>{children}</AppProvider>
      </body>
    </html>
  );
}
