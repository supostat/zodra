import Image from "next/image"
import { Github } from "lucide-react"

export function Footer() {
  return (
    <footer className="border-t border-border">
      <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 px-6 py-6">
        <Image
          src="/logo.svg"
          alt="Zodra"
          width={150}
          height={30}
          className="h-10 w-auto"
        />

        <div className="flex items-center gap-6 text-sm text-muted-foreground">
          <a href="/docs" className="hover:text-foreground transition-colors">
            Docs
          </a>
          <a
            href="https://github.com/supostat/zodra"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 hover:text-foreground transition-colors"
          >
            <Github className="w-4 h-4" />
            <span>GitHub</span>
          </a>
          <span>MIT License</span>
        </div>
      </div>
    </footer>
  )
}
