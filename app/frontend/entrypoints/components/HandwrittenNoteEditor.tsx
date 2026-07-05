import React, { useCallback, useEffect, useMemo, useRef, useState } from "react"
import {
  Excalidraw,
  restore,
  getSceneVersion,
  exportToBlob,
} from "@excalidraw/excalidraw"
import "@excalidraw/excalidraw/index.css"
import { csrfToken } from "../utils/csrf"

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
const TITLE_DEBOUNCE_MS = 800
const THUMBNAIL_MAX_SIZE = 480

type SaveStatus = "idle" | "saving" | "saved" | "error"

interface SceneData {
  elements?: readonly unknown[]
  appState?: Record<string, unknown>
}

// サムネイル生成に使うシーンの静的スナップショット。
// ライブなExcalidraw APIに依存させないことで、Turbo遷移などで
// コンポーネントがunmountされた後でもエクスポートを完走できる
type ExportInput = Parameters<typeof exportToBlob>[0]
interface SceneSnapshot {
  elements: ExportInput["elements"]
  appState: ExportInput["appState"]
  files: ExportInput["files"]
}

interface Props {
  updateUrl: string
  thumbnailUrl: string
  viewMode: boolean
  thumbnailMissing: boolean
  initialSceneData: SceneData
}

export default function HandwrittenNoteEditor({
  updateUrl,
  thumbnailUrl,
  viewMode,
  thumbnailMissing,
  initialSceneData,
}: Props): React.JSX.Element {
  const apiRef = useRef<ExcalidrawImperativeAPI | null>(null)
  const saveTimerRef = useRef<number | null>(null)
  const thumbnailSeqRef = useRef(0)
  const lastSavedMarkerRef = useRef<string | null>(null)
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

  // サムネイルは補助情報。失敗しても本体の保存フローには影響させない
  const uploadThumbnail = useCallback(
    async (snapshot: SceneSnapshot, options: { keepalive?: boolean } = {}) => {
      if (snapshot.elements.length === 0) return
      const seq = ++thumbnailSeqRef.current

      try {
        const blob = await exportToBlob({
          elements: snapshot.elements,
          appState: snapshot.appState,
          files: snapshot.files,
          maxWidthOrHeight: THUMBNAIL_MAX_SIZE,
          mimeType: "image/png",
        })
        // エクスポート中に新しいシーンのアップロードが始まっていたら、
        // 古いサムネイルで上書きしないよう破棄する
        if (seq !== thumbnailSeqRef.current) return

        const form = new FormData()
        form.append("thumbnail", blob, "thumbnail.png")
        const postForm = (keepalive: boolean): Promise<Response> =>
          fetch(thumbnailUrl, {
            method: "PATCH",
            headers: {
              "X-CSRF-Token": csrfToken(),
              Accept: "application/json",
            },
            body: form,
            keepalive,
          })
        try {
          await postForm(options.keepalive ?? false)
        } catch (error) {
          // keepalive fetchはボディが64KBを超えると即時例外になる。
          // ページがまだ生きていれば通常のfetchで再送する
          if (!options.keepalive) throw error
          await postForm(false)
        }
      } catch {
        // no-op
      }
    },
    [thumbnailUrl]
  )

  const doSave = useCallback(
    async (options: { keepalive?: boolean } = {}) => {
      const api = apiRef.current
      const marker = sceneMarker()
      if (!api || marker === null || marker === lastSavedMarkerRef.current)
        return
      const scene = buildPersistedScene()
      if (!scene) return

      // 保存対象と同じシーンをここで静的にキャプチャしておく。
      // 保存完了時にはTurbo遷移でunmount済みのことがあり、
      // その時点のAPIからは要素を取得できないため
      const snapshot: SceneSnapshot = {
        elements: scene.elements,
        appState: { ...api.getAppState() },
        files: api.getFiles(),
      }

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
        // 保存が成功したシーンをそのままサムネイルにする。
        // 別タイマーに遅延させると、発火前にページを離れたとき取り逃す
        void uploadThumbnail(snapshot, options)
      } catch {
        setStatus("error")
      }
    },
    [sceneMarker, buildPersistedScene, updateUrl, uploadThumbnail]
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

  // 描画中のonChangeは毎フレーム発火するため、ここでは重い処理をしない。
  // シーンバージョンの計算・比較は保存時（debounce後）にまとめて行う
  const handleChange = useCallback(() => {
    if (viewMode) return
    if (lastSavedMarkerRef.current === null) {
      // 初回onChange（マウント直後の復元描画）は保存対象にしない
      lastSavedMarkerRef.current = sceneMarker()
      return
    }

    if (saveTimerRef.current !== null) {
      window.clearTimeout(saveTimerRef.current)
    }
    saveTimerRef.current = window.setTimeout(() => {
      saveTimerRef.current = null
      void doSave()
    }, AUTOSAVE_DEBOUNCE_MS)
  }, [viewMode, sceneMarker, doSave])

  // タイトル入力はReactの外（ヘッダー行）にあるため、直接リッスンする
  useEffect(() => {
    if (viewMode) return

    const input = document.querySelector<HTMLInputElement>(
      "#handwritten-note-title"
    )
    if (!input) return

    let timer: number | null = null
    let lastSavedTitle = input.value

    const saveTitle = async (): Promise<void> => {
      if (input.value === lastSavedTitle) return
      const title = input.value
      setStatus("saving")
      try {
        const response = await fetch(updateUrl, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken(),
            Accept: "application/json",
          },
          body: JSON.stringify({ handwritten_note: { title } }),
        })
        if (!response.ok) throw new Error(`save failed: ${response.status}`)
        lastSavedTitle = title
        setStatus("saved")
      } catch {
        setStatus("error")
      }
    }

    const onInput = (): void => {
      if (timer !== null) window.clearTimeout(timer)
      timer = window.setTimeout(() => {
        timer = null
        void saveTitle()
      }, TITLE_DEBOUNCE_MS)
    }
    const onBlur = (): void => {
      if (timer !== null) {
        window.clearTimeout(timer)
        timer = null
      }
      void saveTitle()
    }

    input.addEventListener("input", onInput)
    input.addEventListener("blur", onBlur)
    return () => {
      input.removeEventListener("input", onInput)
      input.removeEventListener("blur", onBlur)
      if (timer !== null) window.clearTimeout(timer)
    }
  }, [viewMode, updateUrl])

  useEffect(() => {
    if (viewMode) return

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
  }, [viewMode, flushSave])

  // 過去にアップロードを取り逃したサムネイルの自己修復。
  // サーバー側に未添付でシーンに要素があれば、開いただけで生成して送る
  // (閲覧専用のモバイルで開いた場合も含む)
  useEffect(() => {
    if (!thumbnailMissing) return
    if (initialData.elements.length === 0) return
    void uploadThumbnail({
      elements: initialData.elements,
      appState: initialData.appState,
      files: initialData.files,
    })
  }, [thumbnailMissing, initialData, uploadThumbnail])

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
      viewModeEnabled={viewMode}
      renderTopRightUI={
        viewMode
          ? undefined
          : () => (
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
            )
      }
    />
  )
}
