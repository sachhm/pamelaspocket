import { useState } from "react"
import { Pressable, ScrollView, StyleSheet, TextInput, View } from "react-native"
import { router } from "expo-router"

import { compareWhen } from "@/src/domain/time"
import {
  AiKind,
  ButtonTone,
  CardTone,
  Escalation,
  Known,
  MessageSource,
  Role,
  Thread,
} from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { AiMark, Body, Button, Card, Meta } from "@/src/ui/bits"
import { Color, Font, MIN_TAP, Space } from "@/src/theme"

export default function Chat() {
  const { actor, state, sendChat, sendToOwner } = usePocket()
  const [draft, setDraft] = useState("")

  if (!actor) {
    return null
  }

  const notes = state.messages
    .filter((note) => note.thread === Thread.Care)
    .sort((a, b) => compareWhen(a.when, b.when))

  function onSend() {
    sendChat(draft)
    setDraft("")
  }

  return (
    <View style={styles.root}>
      <ScrollView
        style={styles.list}
        contentContainerStyle={styles.scrollPad}
        keyboardShouldPersistTaps="handled"
      >
        <Meta>Care chat</Meta>
        {actor.role === Role.Staff ? null : (
          <Pressable onPress={() => router.push("/guide")} style={styles.guide}>
            <Body>Pocket Guide</Body>
            <Meta>Private. Not part of the diary.</Meta>
          </Pressable>
        )}
        {notes.map((note) => {
          const ai = note.source === MessageSource.Ai

          return (
            <Card key={note.id} tone={ai ? CardTone.Ai : CardTone.Note}>
              {ai ? <AiMark kind={AiKind.Reply} /> : <Meta>{note.author}</Meta>}
              <Body>{note.body}</Body>
              {ai && note.known === Known.No && note.escalation !== Escalation.Sent && actor.role !== Role.Owner ? (
                <Button label="Send to Alex" tone={ButtonTone.Quiet} onPress={() => sendToOwner(note.id)} />
              ) : null}
              {note.escalation === Escalation.Sent ? <Meta>Sent to Alex</Meta> : null}
            </Card>
          )
        })}
      </ScrollView>
      <View style={styles.composer}>
        <TextInput
          value={draft}
          onChangeText={setDraft}
          placeholder="Ask about Pamela"
          placeholderTextColor={Color.muted}
          style={styles.input}
          onSubmitEditing={onSend}
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
  scrollPad: {
    padding: Space.lg,
    gap: Space.sm,
  },
  guide: {
    cursor: "pointer",
  },
  composer: {
    flexDirection: "row",
    gap: Space.sm,
    alignItems: "center",
    padding: Space.md,
    backgroundColor: Color.ivory,
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
