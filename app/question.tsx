import { useEffect, useState } from "react"
import { Href, router, useLocalSearchParams } from "expo-router"

import { ButtonTone, FieldPrivacy, FieldSize, Role } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Body, Button, Field, Meta } from "@/src/ui/bits"
import { Guard } from "@/src/ui/guard"
import { Screen } from "@/src/ui/screen"

export default function Question() {
  return (
    <Guard roles={[Role.Owner, Role.Family]}>
      <QuestionForm />
    </Guard>
  )
}

function QuestionForm() {
  const { state, saveAnswer } = usePocket()
  const params = useLocalSearchParams<{ id?: string }>()
  const raw = Array.isArray(params.id) ? params.id[0] : params.id
  const prompt = state.prompts.find((item) => item.id === raw) ?? state.prompts[0]
  const [draft, setDraft] = useState(prompt?.answer ?? "")
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    setDraft(prompt?.answer ?? "")
    setSaved(false)
  }, [prompt?.id])

  if (!prompt) {
    return (
      <Screen title="About Pamela">
        <Body>There are no questions yet.</Body>
      </Screen>
    )
  }

  const index = state.prompts.findIndex((item) => item.id === prompt.id)
  const next = state.prompts[index + 1]

  function onSave() {
    saveAnswer(prompt.id, draft)
    setSaved(true)
  }

  return (
    <Screen
      title="About Pamela"
      footer={<Button label="Save answer" tone={ButtonTone.Primary} onPress={onSave} />}
    >
      <Meta>
        Question {index + 1} of {state.prompts.length}
      </Meta>
      <Body>{prompt.ask}</Body>
      <Field
        label="Answer"
        value={draft}
        onChange={(value) => {
          setDraft(value)
          setSaved(false)
        }}
        privacy={FieldPrivacy.Public}
        size={FieldSize.Story}
      />
      {saved ? <Meta>Saved for this demo.</Meta> : null}
      {next ? (
        <Button
          label="Next question"
          tone={ButtonTone.Quiet}
          onPress={() => router.replace(`/question?id=${next.id}` as Href)}
        />
      ) : (
        <Button label="Done" tone={ButtonTone.Quiet} onPress={() => router.back()} />
      )}
    </Screen>
  )
}
