import Link from "@tiptap/extension-link"
import { Extension, InputRule } from "@tiptap/core"
import DOMPurify from "dompurify"

export const SAFE_MEMO_LINK_REL = "noopener noreferrer nofollow ugc"
export const SAFE_MEMO_LINK_TARGET = "_blank"

const SAFE_MEMO_LINK_CLASS = "memo-link"
const MARKDOWN_LINK_PATTERN = /\[([^\]\n]{1,200})\]\((https?:\/\/[^\s<>"']{1,2048}?)\)/gi
const SKIP_MARKDOWN_LINK_TAGS = new Set(["A", "CODE", "PRE", "SCRIPT", "STYLE"])

const SAFE_MEMO_TAGS = [
  "p",
  "br",
  "strong",
  "em",
  "a",
  "ul",
  "ol",
  "li",
  "blockquote",
  "h1",
  "h2",
  "h3",
  "h4",
  "h5",
  "h6",
  "code",
  "pre",
  "span",
  "hr",
  "s",
]

const SAFE_MEMO_ATTRIBUTES = ["href", "title", "target", "rel", "class"]

const hasMarkdownLink = (text: string): boolean => {
  MARKDOWN_LINK_PATTERN.lastIndex = 0
  return MARKDOWN_LINK_PATTERN.test(text)
}

const sanitizeMemoHtmlToFragment = (html: string): DocumentFragment => {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: SAFE_MEMO_TAGS,
    ALLOWED_ATTR: SAFE_MEMO_ATTRIBUTES,
    ALLOWED_URI_REGEXP: /^https?:\/\//i,
    RETURN_DOM_FRAGMENT: true,
  })
}

const serializeMemoFragment = (fragment: DocumentFragment): string => {
  const template = document.createElement("template")
  template.content.append(fragment)
  return template.innerHTML
}

export const normalizeSafeMemoUrl = (value: string | null | undefined): string | null => {
  const trimmed = value?.trim()
  if (!trimmed) return null

  try {
    const url = new URL(trimmed)
    return url.protocol === "http:" || url.protocol === "https:" ? url.href : null
  } catch {
    return null
  }
}

const shouldSkipMarkdownLinkNode = (node: Node): boolean => {
  let parent = node.parentElement

  while (parent) {
    if (SKIP_MARKDOWN_LINK_TAGS.has(parent.tagName)) return true
    parent = parent.parentElement
  }

  return false
}

const renderMarkdownLinksInFragment = (fragment: DocumentFragment): void => {
  const walker = document.createTreeWalker(fragment, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      if (shouldSkipMarkdownLinkNode(node)) return NodeFilter.FILTER_REJECT
      return hasMarkdownLink(node.textContent ?? "") ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT
    },
  })

  const textNodes: Text[] = []
  while (walker.nextNode()) {
    textNodes.push(walker.currentNode as Text)
  }

  textNodes.forEach((textNode) => {
    const text = textNode.textContent ?? ""
    const fragment = document.createDocumentFragment()
    let cursor = 0
    let hasReplacement = false

    MARKDOWN_LINK_PATTERN.lastIndex = 0
    Array.from(text.matchAll(MARKDOWN_LINK_PATTERN)).forEach((match) => {
      const [raw, label, url] = match
      const index = match.index ?? 0
      const safeUrl = normalizeSafeMemoUrl(url)
      const safeLabel = label.trim()

      if (!safeUrl || !safeLabel) return

      fragment.append(document.createTextNode(text.slice(cursor, index)))

      const anchor = document.createElement("a")
      anchor.href = safeUrl
      anchor.target = SAFE_MEMO_LINK_TARGET
      anchor.rel = SAFE_MEMO_LINK_REL
      anchor.className = SAFE_MEMO_LINK_CLASS
      anchor.textContent = safeLabel
      fragment.append(anchor)

      cursor = index + raw.length
      hasReplacement = true
    })

    if (!hasReplacement) return

    fragment.append(document.createTextNode(text.slice(cursor)))
    textNode.replaceWith(fragment)
  })
}

const enforceSafeMemoAnchors = (root: ParentNode): void => {
  root.querySelectorAll("a").forEach((anchor) => {
    const safeUrl = normalizeSafeMemoUrl(anchor.getAttribute("href"))

    if (!safeUrl) {
      anchor.replaceWith(...Array.from(anchor.childNodes))
      return
    }

    anchor.setAttribute("href", safeUrl)
    anchor.setAttribute("target", SAFE_MEMO_LINK_TARGET)
    anchor.setAttribute("rel", SAFE_MEMO_LINK_REL)
    anchor.classList.add(SAFE_MEMO_LINK_CLASS)
  })
}

export const renderMarkdownLinksToAnchors = (html: string): string => {
  const fragment = sanitizeMemoHtmlToFragment(html)
  renderMarkdownLinksInFragment(fragment)
  enforceSafeMemoAnchors(fragment)
  return serializeMemoFragment(fragment)
}

export const sanitizeMemoHtml = (html: string): string => {
  const fragment = sanitizeMemoHtmlToFragment(html)
  enforceSafeMemoAnchors(fragment)
  return serializeMemoFragment(fragment)
}

export const prepareMemoHtmlForSave = (html: string): string => {
  return renderMarkdownLinksToAnchors(html)
}

export const prepareMemoHtmlForDisplay = prepareMemoHtmlForSave

export const createMemoLinkExtension = (openOnClick: boolean) => {
  return Link.configure({
    autolink: true,
    linkOnPaste: true,
    openOnClick,
    protocols: ["http", "https"],
    defaultProtocol: "https",
    HTMLAttributes: {
      target: SAFE_MEMO_LINK_TARGET,
      rel: SAFE_MEMO_LINK_REL,
      class: SAFE_MEMO_LINK_CLASS,
    },
    isAllowedUri: (url) => normalizeSafeMemoUrl(url) !== null,
    shouldAutoLink: (url) => normalizeSafeMemoUrl(url) !== null,
  })
}

export const MarkdownLinkInputExtension = Extension.create({
  name: "markdownLinkInput",

  addInputRules() {
    return [
      new InputRule({
        find: /\[([^\]\n]{1,200})\]\((https?:\/\/[^\s<>"']{1,2048}?)\)$/,
        handler: ({ state, range, match }) => {
          const label = match[1]?.trim()
          const safeUrl = normalizeSafeMemoUrl(match[2])
          const linkMark = state.schema.marks.link

          if (!label || !safeUrl || !linkMark) return null

          state.tr.replaceWith(
            range.from,
            range.to,
            state.schema.text(label, [linkMark.create({ href: safeUrl })])
          )
        },
      }),
    ]
  },
})
