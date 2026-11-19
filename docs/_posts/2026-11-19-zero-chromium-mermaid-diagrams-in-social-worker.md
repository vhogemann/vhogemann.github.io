---
layout: post
date: 2026-11-19 21:08:22 +0000
image: /assets/images/posts/2026-11-19-zero-chromium-mermaid-diagrams-in-social-worker/diagram-zero-chromium-diagram-pipeline-83e2a457.png
title: "Zero-Chromium Mermaid Diagrams in Social Worker"
tags: [mermaid, typescript, mcp, social-worker]
excerpt: "Agentic Mermaid diagram rendering in Social Worker with zero headless Chromium, pure TypeScript via beautiful-mermaid, and high-DPI social cards in ~40ms."
---

We just shipped agentic Mermaid diagram rendering in **Social Worker** — with zero headless Chromium, pure TypeScript rendering via `beautiful-mermaid`, and social-ready cards generated in roughly **40ms**.

![Zero-Chromium Diagram Pipeline](/assets/images/posts/2026-11-19-zero-chromium-mermaid-diagrams-in-social-worker/diagram-zero-chromium-diagram-pipeline-83e2a457.png)

## How It Works

Instead of spinning up a heavy Puppeteer or Playwright browser process inside Docker just to rasterize diagrams, our `image-engine` microservice renders standard Mermaid definitions straight to SVG in pure TypeScript, resolves CSS custom properties for `librsvg`, and composites the result onto a framed high-DPI card with Sharp and `@napi-rs/canvas`.

Agents in both the in-app Chat composer and the MCP server can invoke `render_diagram` with standard Mermaid syntax — including `flowchart`, `sequence`, `state`, `class`, and `erDiagram` — and immediately get back a media asset ready to embed in threads or blog posts.

![MCP Tool Execution Flow](/assets/images/posts/2026-11-19-zero-chromium-mermaid-diagrams-in-social-worker/diagram-mcp-tool-execution-flow-80927001.png)

## Aspect Ratios, Themes, and Presets

To match the rest of Social Worker's visual tooling (like `render_chart`), the diagram pipeline supports:

- **Automatic aspect-ratio selection**: Picks `16:9`, `1:1`, or `4:5` based on the rendered diagram's natural dimensions.
- **Dark and light card framing**: Consistent typography, padding, and titles across charts and diagrams.
- **15 built-in presets**: Including `tokyo-night`, `dracula`, and `nord`.

![Social Worker Draft Lifecycle](/assets/images/posts/2026-11-19-zero-chromium-mermaid-diagrams-in-social-worker/diagram-social-worker-draft-lifecycle-74c1bd1c.png)
