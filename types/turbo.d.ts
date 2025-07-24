export {}

declare global {
  interface TurboVisitOptions {
    frame?: string
    action?: "advance" | "replace" | "restore"
    historyChanged?: boolean
  }

  interface TurboController {
    visit(url: string, options?: TurboVisitOptions): void
  }

  var Turbo: TurboController
}