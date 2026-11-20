import { useState } from "react"
import { ScrollView, StyleSheet, TextInput, View } from "react-native"

import { compareWhen } from "@/src/domain/time"
import { AiKind, ButtonTone, CardTone, MessageSource, Role, Thread } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { AiMark, Body, Button, Card, Meta } from "@/src/ui/bits"
import { Guard } from "@/src/ui/guard"
import { TopBar } from "@/src/ui/screen"
import { Color, Font, MIN_TAP, Space } from "@/src/theme"

export default function Guide() {
  return (
    <Guard roles={[Role.Owner, Role.Family]}>
      <GuideThread />
    </Guard>
  )
}

function GuideThread() {
  const { state, sendGuide } = usePocket()
  const [draft, setDraft] = useState("")
  const notes = state.messages
    .filter((note) => note.thread === Thread.Guide)
    .sort((a, b) => compareWhen(a.when, b.when))

  function onSend() {
    sendGuide(draft)
    setDraft("")
  }

  return (
    <View style={styles.root}>
      <TopBar title="Pocket Guide" />
      <ScrollView style={styles.list} contentContainerStyle={styles.pad} keyboardShouldPersistTaps="handled">
        <Meta>Pocket Guide</Meta>
        <Body>A private place to vent or think. Not medical advice, and not an emergency service.</Body>
        {notes.map((note) => {
          const ai = note.source === MessageSource.Ai

          return (
            <Card key={note.id} tone={ai ? CardTone.Ai : CardTone.Note}>
              {ai ? <AiMark kind={AiKind.Reply} /> : <Meta>{note.author}</Meta>}
              <Body>{note.body}</Body>
            </Card>
          )
        })}
      </ScrollView>
      <View style={styles.composer}>
        <TextInput
          value={draft}
          onChangeText={setDraft}
          placeholder="Say what's on your mind"
          placeholderTextColor={Color.muted}
          style={styles.input}
        />
        <Button label="Send" tone={ButtonTone.Primary} onPress={onSend} disabled={!draft.trim()} />
      </View>
    </View>
  )
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: Color.ivory,
  },
  list: {
    flex: 1,
  },
  pad: {
    padding: Space.lg,
    gap: Space.sm,
  },
  composer: {
    flexDirection: "row",
    gap: Space.sm,
    alignItems: "center",
    padding: Space.md,
  },
  input: {
    flex: 1,
    minHeight: MIN_TAP,
    borderRadius: 12,
    backgroundColor: Color.white,
    paddingHorizontal: 14,
    fontFamily: Font.body,
    fontSize: 18,
    color: Color.brown,
  },
})
