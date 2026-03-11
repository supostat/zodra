import { DynamicCodeBlock } from "fumadocs-ui/components/dynamic-codeblock"
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
import { createApiClient } from '@zodra/client'
import { contracts } from './zodra/contracts'

const api = createApiClient({
  baseUrl: '/api/v1',
  contracts,
})

const { data } = await api.posts.create({
  title: "Hello World",
  body: "My first post",
})`

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
              <div className="flex items-center justify-center w-10 h-10 rounded-full bg-brand text-white font-bold">
                1
              </div>
              <h3 className="text-xl font-semibold">Define in Ruby</h3>
            </div>
            <p className="text-muted-foreground">
              Use the Zodra DSL to define types, contracts, and API routes.
            </p>
            <DynamicCodeBlock code={step1Code} lang="ruby" />
          </div>

          {/* Step 2 */}
          <div className="flex flex-col items-center justify-center py-8 lg:h-full lg:pt-16">
            <div className="flex lg:flex-col items-center gap-4">
              <RefreshCw className="w-8 h-8 lg:w-12 lg:h-12 text-brand animate-pulse" />
              <div className="text-center">
                <h3 className="font-semibold lg:text-xl">Zodra Generates</h3>
                <p className="text-muted-foreground mt-1 lg:mt-2 text-sm">
                  <span className="lg:hidden">TS types + Zod schemas</span>
                  <span className="hidden lg:inline">TypeScript types, Zod schemas, and a typed client</span>
                </p>
              </div>
              <ArrowRight className="hidden lg:block w-8 h-8 text-muted-foreground" />
            </div>
          </div>

          {/* Step 3 */}
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="flex items-center justify-center w-10 h-10 rounded-full bg-brand text-white font-bold">
                3
              </div>
              <h3 className="text-xl font-semibold">Use in Frontend</h3>
            </div>
            <p className="text-muted-foreground">
              Import generated schemas with full TypeScript inference and runtime validation.
            </p>
            <DynamicCodeBlock code={step3Code} lang="typescript" />
          </div>
        </div>
      </div>
    </section>
  )
}
