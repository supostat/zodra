import { CodeBlock } from "@/components/code-block"
import { ArrowRight, RefreshCw } from "lucide-react"

const step1Code = `# Define types in Ruby
Zodra.type :post do
  uuid :id
  string :title, min: 1
  string :body
  boolean :published, default: false
  timestamps
end`

const step3Code = `// Use in your frontend
import { PostSchema, type Post } from './zodra'

function createPost(data: Omit<Post, 'id'>) {
  const validated = PostSchema.omit({ id: true }).parse(data)
  return api.post('/posts', validated)
}`

export function HowItWorks() {
  return (
    <section className="py-24 px-6 lg:px-12">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
            How it works
          </h2>
          <p className="mt-4 text-muted-foreground text-lg max-w-xl mx-auto">
            Three simple steps to type-safe bliss
          </p>
        </div>

        <div className="grid lg:grid-cols-3 gap-8 items-start">
          {/* Step 1 */}
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="flex items-center justify-center w-10 h-10 rounded-full bg-[#C9184A] text-white font-bold">
                1
              </div>
              <h3 className="text-xl font-semibold">Define in Ruby</h3>
            </div>
            <p className="text-muted-foreground">
              Use the Zodra DSL to define types, contracts, and API routes.
            </p>
            <CodeBlock code={step1Code} language="ruby" />
          </div>

          {/* Step 2 - Arrow */}
          <div className="hidden lg:flex flex-col items-center justify-center h-full pt-16">
            <div className="flex flex-col items-center gap-4">
              <RefreshCw className="w-12 h-12 text-[#C9184A] animate-pulse" />
              <div className="text-center">
                <h3 className="text-xl font-semibold">Zodra Generates</h3>
                <p className="text-muted-foreground mt-2 text-sm">
                  TypeScript types, Zod schemas, and a typed client
                </p>
              </div>
              <ArrowRight className="w-8 h-8 text-muted-foreground" />
            </div>
          </div>

          {/* Mobile Step 2 */}
          <div className="lg:hidden flex items-center justify-center py-8">
            <div className="flex items-center gap-4">
              <RefreshCw className="w-8 h-8 text-[#C9184A]" />
              <div>
                <h3 className="font-semibold">Zodra Generates</h3>
                <p className="text-muted-foreground text-sm">TS types + Zod schemas</p>
              </div>
              <ArrowRight className="w-6 h-6 text-muted-foreground" />
            </div>
          </div>

          {/* Step 3 */}
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="flex items-center justify-center w-10 h-10 rounded-full bg-[#C9184A] text-white font-bold">
                3
              </div>
              <h3 className="text-xl font-semibold">Use in Frontend</h3>
            </div>
            <p className="text-muted-foreground">
              Import generated schemas with full TypeScript inference and runtime validation.
            </p>
            <CodeBlock code={step3Code} language="typescript" />
          </div>
        </div>
      </div>
    </section>
  )
}
