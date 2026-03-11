import { Hero } from "@/components/sections/hero"
import { HowItWorks } from "@/components/sections/how-it-works"
import { Features } from "@/components/sections/features"
import { CodeExample } from "@/components/sections/code-example"
import { Install } from "@/components/sections/install"
import { Footer } from "@/components/sections/footer"

export default function Home() {
  return (
    <main className="min-h-screen">
      <Hero />
      <HowItWorks />
      <Features />
      <CodeExample />
      <Install />
      <Footer />
    </main>
  )
}
