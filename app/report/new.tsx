import { useState } from "react"
import { router } from "expo-router"

import { ButtonTone, FieldPrivacy, FieldSize, Role } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Body, Button, Field } from "@/src/ui/bits"
import { Guard } from "@/src/ui/guard"
import { Screen } from "@/src/ui/screen"

export default function NewReport() {
  return (
    <Guard roles={[Role.Owner]}>
      <ReportForm />
    </Guard>
  )
}

function ReportForm() {
  const { addReport } = usePocket()
  const [title, setTitle] = useState("")
  const [author, setAuthor] = useState("")
  const [note, setNote] = useState("")
  const [original, setOriginal] = useState("")
  const [error, setError] = useState("")

  async function onSave() {
    if (!title.trim() || !original.trim()) {
      setError("Add a title and the report text.")
      return
    }

    try {
      const saved = await addReport({ title, author, note, original })

      if (!saved) {
        setError("That report was not saved.")
        return
      }

      router.back()
    } catch {
      setError("The document service did not answer.")
    }
  }

  return (
    <Screen
      title="Add a report"
      footer={<Button label="Save report" tone={ButtonTone.Primary} onPress={() => void onSave()} />}
    >
      <Body>The original is kept. A plain-English summary is added beside it.</Body>
      <Field label="Title" value={title} onChange={setTitle} privacy={FieldPrivacy.Public} size={FieldSize.Line} />
      <Field label="Author" value={author} onChange={setAuthor} privacy={FieldPrivacy.Public} size={FieldSize.Line} />
      <Field label="Short note" value={note} onChange={setNote} privacy={FieldPrivacy.Public} size={FieldSize.Line} />
      <Field
        label="Report text"
        value={original}
        onChange={setOriginal}
        privacy={FieldPrivacy.Public}
        size={FieldSize.Story}
        hint="Paste the report"
      />
      {error ? <Body>{error}</Body> : null}
    </Screen>
  )
}
