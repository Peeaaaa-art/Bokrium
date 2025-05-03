// app/javascript/rich_editor.js
import React from "react";
import { createRoot } from "react-dom/client";
import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";

const mountedRoots = new Map(); // DOM要素とReact Rootのマッピング

const RichEditor = ({ element }) => {
  const initialContent = element.dataset.initialContent || "";
  const memoId = element.dataset.memoId || "new";
  const hiddenField = document.getElementById(`memo_content_input_${memoId}`);

  const editor = useEditor({
    extensions: [StarterKit],
    content: initialContent,
    autofocus: false,
    editable: true,
    onUpdate: ({ editor }) => {
      if (hiddenField) hiddenField.value = editor.getHTML();
    },
  });

  if (!editor) return null;

  return <EditorContent editor={editor} className="ProseMirror rhodia-grid-bg" />;
};

// ✅ すべての .rich-editor-root をマウント（通常表示用）
export function mountEditors() {
  document.querySelectorAll(".rich-editor-root").forEach((element) => {
    mountRichEditor(element);
  });
}

// ✅ 単体エディタをマウント（モーダルなど）
export function mountRichEditor(selectorOrElement) {
  const element =
    typeof selectorOrElement === "string"
      ? document.querySelector(selectorOrElement)
      : selectorOrElement;

  if (!element) return;

  const prevRoot = mountedRoots.get(element);
  if (prevRoot) {
    prevRoot.unmount();
    mountedRoots.delete(element);
  }

  const root = createRoot(element);
  root.render(<RichEditor element={element} />);
  mountedRoots.set(element, root);
}

// Turboで再読み込み時にエディタ再描画（index表示用）
document.addEventListener("turbo:load", mountEditors);
document.addEventListener("turbo:frame-load", mountEditors);