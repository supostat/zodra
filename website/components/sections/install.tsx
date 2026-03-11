"use client"

import { useState } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Check, Copy, Gem, Package } from "lucide-react"

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false)

  const copy = async () => {
    await navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <button
      onClick={copy}
      className="p-2 rounded-md hover:bg-secondary transition-colors"
      aria-label="Copy to clipboard"
    >
      {copied ? (
        <Check className="w-4 h-4 text-green-400" />
      ) : (
        <Copy className="w-4 h-4 text-muted-foreground" />
      )}
    </button>
  )
}

export function Install() {
  return (
    <section className="py-24 px-6 lg:px-12 bg-secondary/30">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
            Get started in minutes
          </h2>
          <p className="mt-4 text-muted-foreground text-lg max-w-xl mx-auto">
            Two packages, one unified type system
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-6">
          {/* Ruby Gem */}
          <Card className="bg-card/50 border-border/50">
            <CardContent className="pt-6">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-2 rounded-lg bg-[#C9184A]/10">
                  <Gem className="w-6 h-6 text-[#C9184A]" />
                </div>
                <div>
                  <h3 className="font-semibold">Backend</h3>
                  <p className="text-sm text-muted-foreground">Ruby Gem</p>
                </div>
              </div>
              <div className="flex items-center justify-between bg-[#0d0d0d] rounded-lg px-4 py-3">
                <code className="font-mono text-sm text-foreground">
                  gem <span className="text-amber-300">{'"zodra"'}</span>
                </code>
                <CopyButton text='gem "zodra"' />
              </div>
              <p className="mt-4 text-sm text-muted-foreground">
                Add to your Gemfile and run <code className="font-mono text-[#C9184A]">bundle install</code>
              </p>
            </CardContent>
          </Card>

          {/* NPM Package */}
          <Card className="bg-card/50 border-border/50">
            <CardContent className="pt-6">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-2 rounded-lg bg-[#C9184A]/10">
                  <Package className="w-6 h-6 text-[#C9184A]" />
                </div>
                <div>
                  <h3 className="font-semibold">Frontend</h3>
                  <p className="text-sm text-muted-foreground">NPM Package</p>
                </div>
              </div>
              <div className="flex items-center justify-between bg-[#0d0d0d] rounded-lg px-4 py-3">
                <code className="font-mono text-sm text-foreground">
                  <span className="text-[#C9184A]">npm</span> install <span className="text-cyan-400">@zodra/client</span>
                </code>
                <CopyButton text="npm install @zodra/client" />
              </div>
              <p className="mt-4 text-sm text-muted-foreground">
                Or use <code className="font-mono text-[#C9184A]">pnpm</code> / <code className="font-mono text-[#C9184A]">yarn</code>
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  )
}
