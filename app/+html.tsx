import { ScrollViewStyleReset } from "expo-router/html"
import type { ReactNode } from "react"

export default function Root({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
        <ScrollViewStyleReset />
        <style dangerouslySetInnerHTML={{ __html: page }} />
      </head>
      <body>{children}</body>
    </html>
  )
}

const page = `
html, body, #root { height: 100%; }
body { background-color: #f8dbc9; }
`
