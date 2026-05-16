import { Extension } from "@tiptap/core"
import { Plugin } from "@tiptap/pm/state"
import MarkdownIt from "markdown-it"
import { prepareMemoHtmlForSave } from "./memo_links"

const markdown = new MarkdownIt({
  breaks: false,
  html: false,
  linkify: true,
  typographer: false,
})

const MARKDOWN_BLOCK_PATTERN =
  /(^|\n)\s{0,3}(#{1,6}\s+\S|[-*+]\s+\S|\d+[.)]\s+\S|>\s+\S|```|~~~|---+\s*$)/m
const MARKDOWN_INLINE_PATTERN =
  /(\*\*[^*\n]+?\*\*|__[^_\n]+?__|_[^_\n]+?_|`[^`\n]+?`|\[[^\]\n]{1,200}\]\(https?:\/\/[^\s<>"']{1,2048}?\))/i

export const looksLikeMarkdown = (text: string): boolean => {
  const trimmed = text.trim()
  if (!trimmed) return false

  return MARKDOWN_BLOCK_PATTERN.test(trimmed) || MARKDOWN_INLINE_PATTERN.test(trimmed)
}

export const renderPastedMarkdownToMemoHtml = (text: string): string | null => {
  if (!looksLikeMarkdown(text)) return null

  const html = markdown.render(text)
  const sanitized = prepareMemoHtmlForSave(html).trim()

  return sanitized || null
}

export const MarkdownPasteExtension = Extension.create({
  name: "markdownPaste",

  addProseMirrorPlugins() {
    const editor = this.editor

    return [
      new Plugin({
        props: {
          handlePaste(_view, event) {
            const text = event.clipboardData?.getData("text/plain") ?? ""
            const html = renderPastedMarkdownToMemoHtml(text)

            if (!html) return false

            event.preventDefault()
            return editor.commands.insertContent(html)
          },
        },
      }),
    ]
  },
})
