---
layout: post
title:  "Adventures in Vibe Coding"
date:  2025-06-21 12:00:00 +0000
categories: llm vibe-coding 
image: /assets/Adventures_in_Vibe_Coding.jpg
---

![Adventures in Vibe Coding](/assets/Adventures_in_Vibe_Coding.jpg)

Adventures in Vibe Coding
==

At work I've been working on a side project to build a tool to help me parse and analyze logs from our systems. Since we have GitHub Copilot, I decided to let it do the heavy lifiting, while I navigated through half-remembered Python syntax and the ocasional dive into the documentation. It wasn't a bump free ride, and most often than not I had to correct the code it generated, or even rewrite the whole thing.

The end result is a Jupyter notebook that can fetch and then parse logs, and then generate a Graphviz visualization of the log flow. Here's what it looks like:

![Visualization of a log flow, using the default dark theme](/assets/adventures-in-vibe-coding/default.svg)

Here's where Copilot really started to shine: I had it generate the color palette for the visualization, with just a few hints of what I wanted. It came up with a really nice set of colors, and I was quite suprised by how well it did. I had to tweak a few things, but overall it was a great starting point.

A splash of color
==

At some point I decided to have some fun with the visualization, and started adding theme support. I tried to get the Agent mode to refactor the code to use the theme classes I had created, but it was a complete clusterfuck. On top of refactoring the code to use the theme object, it also started to _"fix"_ the code, and managed to break the whole thing. A few Ctrl+Z later, I decided to ask it instead to just generate a new theme, a Light Theme, and that went way better. Here, take a look:

Light Theme
![Visualization of a log flow, using the Light theme](/assets/adventures-in-vibe-coding/light.svg)

Not only did it generate a new theme, but it also came up with some nice colors that worked well together. But it makes sense, right? Copilot is trained on a lot of code, including CSS that defines themes and styles.

The thing is, how does it know where each color should go?

This is how I define the theme in Python, by defining each individual style as a class, and then combining them into a `Theme` class. Might not be the most Pythonic way to do it, but it makes sense in my Java tainted mind. (Type all the things!)

```python
from dataclasses import dataclass
from typing import Tuple

# Classes to define the styles for the flowchart elements
# These styles are all properties passed to Graphviz elements
# to control their appearance in the generated flowchart.

@dataclass(frozen=True)
class GraphStyle: # Basic style for the graph
    bgcolor: str
    fontcolor: str
    fontname: str

@dataclass(frozen=True)
class GraphLabelStyle: # Style for the graph label
    fontname: str
    fontsize: str
    bgcolor: str

@dataclass(frozen=True)
class NodeStyle: # Style for nodes in the flowchart
    shape: str  # Node shape
    style: str  # Node style
    fillcolor: str  # Node fill color
    fontname: str  # Font name for the node label
    fontsize: str  # Font size for the node label
    fontcolor: str  # Font color for the node label

@dataclass(frozen=True)
class EdgeStyle: # Style for edges in the flowchart
    color: str
    style: str

@dataclass(frozen=True)
class Theme:
    graph: GraphStyle  # Graph style
    label: GraphLabelStyle # Style for the graph label
    edge: EdgeStyle # Default edge style
    node: NodeStyle  # Default node style
    start: NodeStyle  # Style for START nodes
    end: NodeStyle # Style for END nodes
    error_note: NodeStyle # Style for ERROR notes
    error_edge: EdgeStyle  # Style for edges leading to ERROR notes
    warn_note: NodeStyle  # Style for WARN notes
    warn_edge: EdgeStyle # Style for edges leading to WARN notes
    info_note: NodeStyle   # Style for INFO notes
    info_edge: EdgeStyle # Style for edges leading to INFO notes
    service_colors: list[Tuple[str, str]]  # List of (font/border, background) color pairs for service subgraphs
    group_colors: list[Tuple[str, str]]  # Optional group colors for subgraphs
```

The important thing here is the structure. By defining classes and adding comments for each element, I'm giving clues that Copilot can follow to generate the theme. The classes and their comments act as extra context, which helps Copilot understand what I want.

Vibing
==

At this point I was a bit more confident that Copilot wouldn't screw up the code much more, so I asked it for a few themes. For those I gave it minimal directions, and let it do its thing. Here's what it came up with:

Vaporwave Theme - Asked for a 80s vibe and neon colors, and it delivered!
![Visualization of a log flow, using the Vaporwave theme](/assets/adventures-in-vibe-coding/vaporwave.svg)


Unicorn Theme (bright and fluffy) - No notes, perfect!
![Visualization of a log flow, using the Unicorn theme](/assets/adventures-in-vibe-coding/unicorn.svg)


Conclusion
==

Overall, Copilot has been a mixed bag. The inline suggestions are often annoyingly off the mark to the point of being useless. I have had more success with the chat, by giving it clear instructions and adding files to the context. I often find myself writing more comments across the code, already thinking about the next time I'll ask it to generate code.

In general it's great for prototyping, looking for ideas, and generating small boilerplate code that I can then tweak and expand. I don't see it replacing me so soon, and it's pretty clear that to get the most out of it you need the experience to know what to ask and how to guide it.

More Themes
==

Here's all the other themes it generated for me, in case you're curious:

Hotdog Theme (if you know, you know) - After the famous Windows 3.1 theme.
![Visualization of a log flow, using the Hotdog theme](/assets/adventures-in-vibe-coding/hotdog.svg)


I mean, what else would you want? It's not that far off from the original:

![Original Hotdog Stand theme from Windows 3.1](/assets/adventures-in-vibe-coding/win311_hotdog.png)


Gameboy Theme (retro vibes) - This one it came up by itself, I asked for theme suggestions and it came up with this one. Just gave it the green light.
![Visualization of a log flow, using the Gameboy theme](/assets/adventures-in-vibe-coding/gameboy.svg)

Autumn Theme
![Visualization of a log flow, using the Autumn theme](/assets/adventures-in-vibe-coding/autumn.svg)

Cyberpunk Theme
![Visualization of a log flow, using the Cyberpunk theme](/assets/adventures-in-vibe-coding/cyberpunk.svg)

Matrix Theme
![Visualization of a log flow, using the Matrix theme](/assets/adventures-in-vibe-coding/matrix.svg)

Oceanic Theme
![Visualization of a log flow, using the Oceanic theme](/assets/adventures-in-vibe-coding/oceanic.svg)

Solarized Theme
![Visualization of a log flow, using the Solarized theme](/assets/adventures-in-vibe-coding/solarized.svg)