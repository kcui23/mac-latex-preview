# LaTeX Preview for macOS

A lightweight menu bar app that automatically renders LaTeX formulas when you select them in the terminal.

## Demo

Select any LaTeX text in your terminal — a floating overlay renders the formula in real time. Deselect to dismiss.

## Requirements

- macOS 13+
- Xcode Command Line Tools (`xcode-select --install`)

## Build & Run

```bash
make run
```

This downloads KaTeX automatically on first build.

## Setup

On first launch, grant **Accessibility** permission when prompted:

**System Settings → Privacy & Security → Accessibility → LatexPreview**

You may need to restart the app after granting permission.

## Usage

- A **Σ** icon appears in the menu bar
- Select LaTeX text in any terminal (Terminal.app, iTerm2, etc.)
- Supported formats: `$...$`, `$$...$$`, `\[...\]`, `\(...\)`, or raw LaTeX commands
- The overlay is draggable and auto-positions near your cursor
- Toggle on/off or quit from the menu bar icon

## Examples

Try selecting any of these in your terminal:

```
$\frac{a}{b}$
$$\sum_{i=1}^{n} x_i$$
\int_{0}^{\infty} e^{-x^2} dx = \frac{\sqrt{\pi}}{2}
E = mc^2
\begin{pmatrix} a & b \\ c & d \end{pmatrix}
```
