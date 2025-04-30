import React from "react";
import { createRoot } from "react-dom/client";
import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";

const mountedRoots = new Map(); // root DOM要素ごとに保存

const RichEditor = ({ element }) => {
  const initialContent = element.dataset.initialContent || "";
  const memoId = element.dataset.memoId;
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

  return <EditorContent editor={editor} className="w-100 ProseMirror rhodia-grid-bg" />;
};

function mountEditors() {
  document.querySelectorAll(".rich-editor-root").forEach((element) => {
    // すでに描画済みなら unmount → 再マウント
    const prevRoot = mountedRoots.get(element);
    if (prevRoot) {
      prevRoot.unmount();
      mountedRoots.delete(element);
    }

    const root = createRoot(element);
    root.render(<RichEditor element={element} />);
    mountedRoots.set(element, root);
  });
}

document.addEventListener("turbo:load", mountEditors);
document.addEventListener("turbo:frame-load", mountEditors);