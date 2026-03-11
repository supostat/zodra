import { Button } from "@/components/ui/button"
import { DynamicCodeBlock } from "fumadocs-ui/components/dynamic-codeblock"
import Image from "next/image"
import { Github } from "lucide-react"

const rubyCode = `Zodra.type :user do
  uuid :id
  string :name, min: 1
  string :email
  integer :age, min: 0
  timestamps
end`

const typescriptCode = `import { UserSchema } from './zodra/schemas'

// Full TypeScript inference
const user = {
  id: "550e8400-e29b-41d4-a716-446655440000",
  name: "Alice",
  email: "alice@example.com",
  age: 28,
  created_at: "2024-01-01T00:00:00Z",
  updated_at: "2024-01-01T00:00:00Z",
}

// Runtime validation with Zod
UserSchema.parse(user)`

export function Hero() {
  return (
    <section className="relative min-h-screen flex flex-col">
      {/* Navigation */}
      <nav className="flex items-center justify-end px-6 py-4 lg:px-12">
        <div className="flex items-center gap-4">
          <a
            href="/docs"
            className="text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            Docs
          </a>
          <a
            href="https://github.com/supostat/zodra"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            <Github className="w-5 h-5" />
            <span className="hidden sm:inline">GitHub</span>
          </a>
        </div>
      </nav>

      {/* Hero Content */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 py-12 lg:py-20">
        <div className="max-w-6xl mx-auto text-center">
          <Image
            src="/logo.svg"
            alt="Zodra"
            width={800}
            height={160}
            className="h-40 sm:h-48 w-auto mx-auto mb-8"
            priority
          />
          <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight text-balance">
            Type-safe from{" "}
            <span className="text-brand">Rails</span> to{" "}
            <span className="text-brand">TypeScript</span>
          </h1>

          <p className="mt-6 text-lg sm:text-xl text-muted-foreground max-w-2xl mx-auto text-pretty">
            Define your API once in Rails. Get TypeScript types, Zod schemas,
            and a typed client automatically. Zero drift, zero surprises.
          </p>

          <div className="mt-8 flex flex-col sm:flex-row items-center justify-center gap-4">
            <Button
              size="lg"
              className="bg-brand hover:bg-brand-dark text-white px-8"
              asChild
            >
              <a href="/docs">Get Started</a>
            </Button>
            <Button
              size="lg"
              variant="outline"
              className="border-brand/50 hover:border-brand hover:bg-brand/10 text-foreground"
              asChild
            >
              <a
                href="https://github.com/supostat/zodra"
                target="_blank"
                rel="noopener noreferrer"
              >
                <Github className="w-4 h-4 mr-2" />
                View on GitHub
              </a>
            </Button>
          </div>
        </div>

        {/* Code Comparison */}
        <div className="mt-16 w-full max-w-5xl mx-auto">
          <div className="grid md:grid-cols-2 gap-4">
            <DynamicCodeBlock
              code={rubyCode}
              lang="ruby"
              codeblock={{ title: "app/types/user.rb" }}
            />
            <DynamicCodeBlock
              code={typescriptCode}
              lang="typescript"
              codeblock={{ title: "zodra/schemas.ts" }}
            />
          </div>
        </div>
      </div>

      {/* Gradient decoration */}
      <div className="absolute inset-0 -z-10 overflow-hidden pointer-events-none">
        <div className="absolute top-[10%] left-1/2 -translate-x-1/2 w-250 h-150 bg-brand/8 rounded-full blur-[120px]" />
        <div className="absolute top-[15%] left-1/2 -translate-x-1/2 w-150 h-100 bg-brand-dark/10 rounded-full blur-[80px]" />
      </div>
    </section>
  )
}
