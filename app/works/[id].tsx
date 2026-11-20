import { useState } from "react"
import { useLocalSearchParams } from "expo-router"

import { AiKind, ButtonTone, CardTone, FieldPrivacy, FieldSize } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { AiMark, Body, Button, Card, Field, Meta } from "@/src/ui/bits"
import { Screen } from "@/src/ui/screen"

export default function Works() {
  const { state, addObservation } = usePocket()
  const params = useLocalSearchParams<{ id: string }>()
  const raw = Array.isArray(params.id) ? params.id[0] : params.id
  const card = state.works.find((item) => item.id === raw)
  const [draft, setDraft] = useState("")

  if (!card) {
    return (
      <Screen title="What works">
        <Body>That note is not on Pamela's list.</Body>
      </Screen>
    )
  }

  const worksId = card.id

  function onAdd() {
    addObservation(worksId, draft)
    setDraft("")
  }

  return (
    <Screen title="What works for me">
      <Card tone={CardTone.Soft}>
        <Meta>Situation</Meta>
        <Body>{card.situation}</Body>
        <Meta>What helps</Meta>
        <Body>{card.helps}</Body>
        <Meta>What doesn't help</Meta>
        <Body>{card.hinders}</Body>
      </Card>

      {card.pattern ? (
        <Card tone={CardTone.Ai}>
          <AiMark kind={AiKind.Summary} />
          <Body>{card.pattern}</Body>
          <Meta>From Pamela's own notes. Not a diagnosis.</Meta>
        </Card>
      ) : null}

      {card.observations.length > 0 ? (
        <Card tone={CardTone.Note}>
          <Meta>Seen on a shift</Meta>
          {card.observations.map((line, index) => (
            <Body key={`${line}-${index}`}>{line}</Body>
          ))}
        </Card>
      ) : null}

      <Field
        label="Add what worked"
        value={draft}
        onChange={setDraft}
        privacy={FieldPrivacy.Public}
        size={FieldSize.Story}
        hint="What happened, and what helped?"
      />
      <Button label="Add observation" tone={ButtonTone.Primary} onPress={onAdd} disabled={!draft.trim()} />
    </Screen>
  )
}
