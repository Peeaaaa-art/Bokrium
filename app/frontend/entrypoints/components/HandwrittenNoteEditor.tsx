import React, { useCallback, useEffect, useMemo, useRef, useState } from "react"
import { Excalidraw, restore, getSceneVersion } from "@excalidraw/excalidraw"
import "@excalidraw/excalidraw/index.css"

type ExcalidrawImperativeAPI = Parameters<
  NonNullable<React.ComponentProps<typeof Excalidraw>["excalidrawAPI"]>
>[0]

// 永続化するappStateはシーンの見た目に関わるものだけに絞る
// （zoom・選択状態などのセッション状態はDBに保存しない）
const PERSISTED_APP_STATE_KEYS = [
  "viewBackgroundColor",
  "gridSize",
  "gridModeEnabled",
] as const

const AUTOSAVE_DEBOUNCE_MS = 1200

type SaveStatus = "idle" | "saving" | "saved" | "error"

interface SceneData {
  elements?: readonly unknown[]
  appState?: Record<string, unknown>
}

interface Props {
  updateUrl: string
  initialSceneData: SceneData
}

function csrfToken(): string {
  return (
    document.querySelector<HTMLMetaElement>("meta[name='csrf-token']")
      ?.content ?? ""
  )
}

export default function HandwrittenNoteEditor({
  updateUrl,
  initialSceneData,
}: Props): React.JSX.Element {
  const apiRef = useRef<ExcalidrawImperativeAPI | null>(null)
  const saveTimerRef = useRef<number | null>(null)
  const lastSavedMarkerRef = useRef<string | null>(null)
  const currentMarkerRef = useRef<string | null>(null)
  const [status, setStatus] = useState<SaveStatus>("idle")

  const initialData = useMemo(() => {
    const hasContent =
      Array.isArray(initialSceneData?.elements) &&
      initialSceneData.elements.length > 0
    const restored = restore(
      {
        elements: (initialSceneData?.elements ?? []) as never,
        appState: (initialSceneData?.appState ?? {}) as never,
      },
      null,
      null
    )
    return {
      elements: restored.elements,
      appState: restored.appState,
      files: restored.files,
      scrollToContent: hasContent,
    }
  }, [initialSceneData])

  const buildPersistedScene = useCallback(() => {
    const api = apiRef.current
    if (!api) return null

    const appState = api.getAppState() as unknown as Record<string, unknown>
    const persistedAppState: Record<string, unknown> = {}
    for (const key of PERSISTED_APP_STATE_KEYS) {
      persistedAppState[key] = appState[key]
    }

    return {
      type: "excalidraw",
      version: 2,
      elements: api.getSceneElements(),
      appState: persistedAppState,
    }
  }, [])

  const sceneMarker = useCallback(() => {
    const api = apiRef.current
    if (!api) return null
    const appState = api.getAppState() as unknown as Record<string, unknown>
    const appStatePart = PERSISTED_APP_STATE_KEYS.map(
      (key) => `${key}=${String(appState[key])}`
    ).join(",")
    return `${getSceneVersion(api.getSceneElementsIncludingDeleted())}|${appStatePart}`
  }, [])

  const doSave = useCallback(
    async (options: { keepalive?: boolean } = {}) => {
      const scene = buildPersistedScene()
      const marker = currentMarkerRef.current
      if (!scene || marker === null) return
      if (marker === lastSavedMarkerRef.current) return

      setStatus("saving")
      try {
        const response = await fetch(updateUrl, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken(),
            Accept: "application/json",
          },
          body: JSON.stringify({ handwritten_note: { data: scene } }),
          keepalive: options.keepalive ?? false,
        })
        if (!response.ok) throw new Error(`save failed: ${response.status}`)
        lastSavedMarkerRef.current = marker
        setStatus("saved")
      } catch {
        setStatus("error")
      }
    },
    [buildPersistedScene, updateUrl]
  )

  const flushSave = useCallback(
    (options: { keepalive?: boolean } = {}) => {
      if (saveTimerRef.current !== null) {
        window.clearTimeout(saveTimerRef.current)
        saveTimerRef.current = null
      }
      void doSave(options)
    },
    [doSave]
  )

  const handleChange = useCallback(() => {
    const marker = sceneMarker()
    if (marker === null) return
    if (lastSavedMarkerRef.current === null) {
      // 初回onChange（マウント直後）は保存対象にしない
      lastSavedMarkerRef.current = marker
      currentMarkerRef.current = marker
      return
    }
    if (marker === currentMarkerRef.current) return
    currentMarkerRef.current = marker

    if (saveTimerRef.current !== null) {
      window.clearTimeout(saveTimerRef.current)
    }
    saveTimerRef.current = window.setTimeout(() => {
      saveTimerRef.current = null
      void doSave()
    }, AUTOSAVE_DEBOUNCE_MS)
  }, [sceneMarker, doSave])

  useEffect(() => {
    // iPad Safariはタブをすぐ破棄するので、画面を離れる瞬間に必ず書き出す
    const onPageHide = (): void => flushSave({ keepalive: true })
    const onVisibilityChange = (): void => {
      if (document.visibilityState === "hidden") flushSave({ keepalive: true })
    }
    const onTurboBeforeVisit = (): void => flushSave()

    window.addEventListener("pagehide", onPageHide)
    document.addEventListener("visibilitychange", onVisibilityChange)
    document.addEventListener("turbo:before-visit", onTurboBeforeVisit)
    return () => {
      window.removeEventListener("pagehide", onPageHide)
      document.removeEventListener("visibilitychange", onVisibilityChange)
      document.removeEventListener("turbo:before-visit", onTurboBeforeVisit)
      if (saveTimerRef.current !== null) {
        window.clearTimeout(saveTimerRef.current)
      }
    }
  }, [flushSave])

  const statusLabel: Record<SaveStatus, string> = {
    idle: "",
    saving: "保存中…",
    saved: "保存済み",
    error: "保存に失敗しました",
  }

  return (
    <Excalidraw
      excalidrawAPI={(api) => {
        apiRef.current = api
      }}
      initialData={initialData}
      onChange={handleChange}
      langCode="ja-JP"
      renderTopRightUI={() => (
        <div
          className={`d-flex align-items-center small px-2 ${
            status === "error" ? "text-danger" : "text-secondary"
          }`}
          style={{ whiteSpace: "nowrap" }}
        >
          {status === "error" ? (
            <button
              type="button"
              className="btn btn-sm btn-outline-danger py-0"
              onClick={() => flushSave()}
            >
              {statusLabel[status]}（再試行）
            </button>
          ) : (
            statusLabel[status]
          )}
        </div>
      )}
    />
  )
}
