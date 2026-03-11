import { DocsLayout } from "fumadocs-ui/layouts/docs";
import { source } from "@/lib/source";
import Image from "next/image";
import type { ReactNode } from "react";

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <DocsLayout
      tree={source.getPageTree()}
      nav={{
        title: (
          <Image
            src="/logo.svg"
            alt="Zodra"
            width={360}
            height={72}
            className="h-24 w-auto"
          />
        ),
        url: "/",
      }}
    >
      {children}
    </DocsLayout>
  );
}
