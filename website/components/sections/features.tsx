import { Card, CardContent } from "@/components/ui/card"
import {
  Shield,
  Zap,
  FileCode,
  Feather,
  Server,
  FileCheck
} from "lucide-react"

const features = [
  {
    icon: Shield,
    title: "Contract-based validation",
    description: "Define params and response schemas per action. Validate requests on the backend with generated parsers."
  },
  {
    icon: FileCode,
    title: "Auto-generated Zod schemas",
    description: "Your Ruby type definitions automatically generate Zod schemas and TypeScript interfaces. No manual sync."
  },
  {
    icon: Zap,
    title: "Full TypeScript inference",
    description: "Get complete type inference from your schemas. Your IDE knows exactly what shape your data takes."
  },
  {
    icon: Feather,
    title: "Standalone type DSL",
    description: "Types are defined independently from models. One type, one file, reusable across API versions."
  },
  {
    icon: Server,
    title: "Full API framework",
    description: "Types, contracts, routing, serialization, error handling — everything you need for a Rails API."
  },
  {
    icon: FileCheck,
    title: "Single source of truth",
    description: "One definition in Ruby powers backend validation, frontend types, and API documentation."
  }
]

export function Features() {
  return (
    <section className="py-12 sm:py-16 lg:py-24 px-4 sm:px-6 lg:px-12 bg-secondary/30">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
            Everything you need
          </h2>
          <p className="mt-4 text-muted-foreground text-lg max-w-xl mx-auto">
            Type safety across the stack, without the hassle
          </p>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature) => (
            <Card
              key={feature.title}
              className="bg-card/50 border-border/50 hover:border-brand/30 transition-colors"
            >
              <CardContent className="pt-6">
                <feature.icon className="w-10 h-10 text-brand mb-4" />
                <h3 className="text-lg font-semibold mb-2">{feature.title}</h3>
                <p className="text-muted-foreground text-sm leading-relaxed">
                  {feature.description}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}
