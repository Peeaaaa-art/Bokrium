export const normalizeProseMirrorHtmlForSave = (html: string): string => {
  const div = document.createElement("div")
  div.innerHTML = html

  div.querySelectorAll("br.ProseMirror-trailingBreak").forEach((br) => br.remove())
  preserveSignificantSpaces(div)

  return div.innerHTML
}

const preserveSignificantSpaces = (root: ParentNode): void => {
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT)
  const textNodes: Text[] = []

  while (walker.nextNode()) {
    textNodes.push(walker.currentNode as Text)
  }

  textNodes.forEach((node) => {
    if (isCodeTextNode(node)) return

    node.textContent = node.textContent?.replace(/^ +| {2,}| +$/g, (spaces) => {
      return "\u00a0".repeat(spaces.length)
    }) ?? ""
  })
}

const isCodeTextNode = (node: Text): boolean => {
  let element = node.parentElement

  while (element) {
    if (element.tagName === "CODE" || element.tagName === "PRE") return true
    element = element.parentElement
  }

  return false
}
