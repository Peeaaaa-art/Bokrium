export {}

declare global {
  interface Window {
    hasUnsavedChanges: boolean
  }

  interface HTMLElement {
    dataset: DOMStringMap & {
      initialContent?: string
      memoId?: string
      bookId?: string
      createdAt?: string
      updatedAt?: string
      createdDate?: string
      updatedDate?: string
    }
  }
}