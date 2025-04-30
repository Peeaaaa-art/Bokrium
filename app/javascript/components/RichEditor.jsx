import React, { useEffect } from "react";
import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";

const RichEditor = () => {
  const element = document.getElementById("rich-editor-root");
  const initialContent = element?.dataset?.initialContent || "";

  const editor = useEditor({
    extensions: [StarterKit],
    content: initialContent,
    autofocus: true,
    editable: true,
    onUpdate: ({ editor }) => {
      const html = editor.getHTML();
      const hiddenField = document.getElementById("memo_content_input");
      if (hiddenField) hiddenField.value = html;
    },
  });

  useEffect(() => {
    if (!editor) return;
    const hiddenField = document.getElementById("memo_content_input");
    if (hiddenField) hiddenField.value = editor.getHTML();
  }, [editor]);

  if (!editor) return null; // ← editorが未初期化なら何も表示しない

  return (
    <div>
      <div
        className="form-control rhodia-grid-bg"
        style={{
          minHeight: "9em",
          overflowY: "auto",
          borderRadius: "0.375rem",
        }}
      >
        <EditorContent editor={editor} className="w-100 ProseMirror" />
      </div>
    </div>
  );
};

export default RichEditor;