"use client"

import React, { useState } from "react"
import { cn } from "@/lib/utils"
import { Check, Copy } from "lucide-react"

interface CodeBlockProps {
  code: string
  language?: string
  filename?: string
  className?: string
  showLineNumbers?: boolean
}

export function CodeBlock({ 
  code, 
  language = "typescript", 
  filename,
  className,
  showLineNumbers = false
}: CodeBlockProps) {
  const [copied, setCopied] = useState(false)

  const copyToClipboard = async () => {
    await navigator.clipboard.writeText(code)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const lines = code.split('\n')

  return (
    <div className={cn("relative group rounded-lg overflow-hidden", className)}>
      {filename && (
        <div className="flex items-center justify-between px-4 py-2 bg-[#1a1a1a] border-b border-border">
          <span className="text-xs font-mono text-muted-foreground">{filename}</span>
          <span className="text-xs font-mono text-[#C9184A]">{language}</span>
        </div>
      )}
      <div className="relative">
        <pre className="p-4 overflow-x-auto bg-[#0d0d0d] text-sm">
          <code className="font-mono">
            {lines.map((line, i) => (
              <div key={i} className="table-row">
                {showLineNumbers && (
                  <span className="table-cell pr-4 text-right text-muted-foreground/50 select-none">
                    {i + 1}
                  </span>
                )}
                <span className="table-cell">
                  <SyntaxHighlight line={line} language={language} />
                </span>
              </div>
            ))}
          </code>
        </pre>
        <button
          onClick={copyToClipboard}
          className="absolute top-3 right-3 p-2 rounded-md bg-secondary/50 opacity-0 group-hover:opacity-100 transition-opacity hover:bg-secondary"
          aria-label="Copy code"
        >
          {copied ? (
            <Check className="w-4 h-4 text-green-400" />
          ) : (
            <Copy className="w-4 h-4 text-muted-foreground" />
          )}
        </button>
      </div>
    </div>
  )
}

function SyntaxHighlight({ line, language }: { line: string; language: string }) {
  // Simple syntax highlighting
  const highlightPatterns = {
    ruby: [
      { pattern: /(#.*)$/gm, className: "text-muted-foreground" }, // comments
      { pattern: /\b(class|def|end|validates|include|extend|module|require|attr_accessor|attr_reader)\b/g, className: "text-[#C9184A]" }, // keywords
      { pattern: /\b(true|false|nil)\b/g, className: "text-orange-400" }, // booleans
      { pattern: /:[\w]+/g, className: "text-emerald-400" }, // symbols
      { pattern: /(["'])(?:(?=(\\?))\2.)*?\1/g, className: "text-amber-300" }, // strings
      { pattern: /\b([A-Z][a-zA-Z0-9]*)\b/g, className: "text-cyan-400" }, // constants/classes
    ],
    typescript: [
      { pattern: /(\/\/.*)$/gm, className: "text-muted-foreground" }, // comments
      { pattern: /\b(import|export|from|const|let|type|interface|extends|implements|async|await|return|if|else|function)\b/g, className: "text-[#C9184A]" }, // keywords
      { pattern: /\b(true|false|null|undefined)\b/g, className: "text-orange-400" }, // booleans
      { pattern: /(["'`])(?:(?=(\\?))\2.)*?\1/g, className: "text-amber-300" }, // strings
      { pattern: /\b([A-Z][a-zA-Z0-9]*)\b/g, className: "text-cyan-400" }, // types
      { pattern: /\b(z\.\w+)/g, className: "text-emerald-400" }, // zod methods
    ],
    bash: [
      { pattern: /(#.*)$/gm, className: "text-muted-foreground" }, // comments
      { pattern: /\b(gem|npm|yarn|pnpm|install|add)\b/g, className: "text-[#C9184A]" }, // commands
      { pattern: /(["'])(?:(?=(\\?))\2.)*?\1/g, className: "text-amber-300" }, // strings
    ]
  }

  const patterns = highlightPatterns[language as keyof typeof highlightPatterns] || highlightPatterns.typescript

  let result = line
  const segments: { start: number; end: number; className: string }[] = []

  patterns.forEach(({ pattern, className }) => {
    const regex = new RegExp(pattern)
    let match
    const globalRegex = new RegExp(pattern.source, pattern.flags.includes('g') ? pattern.flags : pattern.flags + 'g')
    
    while ((match = globalRegex.exec(line)) !== null) {
      segments.push({
        start: match.index,
        end: match.index + match[0].length,
        className
      })
    }
  })

  if (segments.length === 0) {
    return <span className="text-foreground/90">{line || '\n'}</span>
  }

  // Sort segments by start position
  segments.sort((a, b) => a.start - b.start)

  // Remove overlapping segments (keep the first one)
  const filtered: typeof segments = []
  for (const seg of segments) {
    const last = filtered[filtered.length - 1]
    if (!last || seg.start >= last.end) {
      filtered.push(seg)
    }
  }

  // Build the highlighted line
  const parts: React.ReactElement[] = []
  let lastEnd = 0

  filtered.forEach((seg, i) => {
    if (seg.start > lastEnd) {
      parts.push(
        <span key={`text-${i}`} className="text-foreground/90">
          {line.slice(lastEnd, seg.start)}
        </span>
      )
    }
    parts.push(
      <span key={`hl-${i}`} className={seg.className}>
        {line.slice(seg.start, seg.end)}
      </span>
    )
    lastEnd = seg.end
  })

  if (lastEnd < line.length) {
    parts.push(
      <span key="text-end" className="text-foreground/90">
        {line.slice(lastEnd)}
      </span>
    )
  }

  return <>{parts.length > 0 ? parts : '\n'}</>
}
