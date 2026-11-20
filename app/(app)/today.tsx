import { Pressable, StyleSheet, Text, View } from "react-native"
import { Href, router } from "expo-router"

import { compareWhen, formatWhen } from "@/src/domain/time"
import {
  AiKind,
  Attachment,
  ButtonTone,
  CardTone,
  DiaryEntry,
  EntryKind,
  QuestionState,
  Role,
  VoiceNote,
} from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { AiMark, Body, Button, Card, Meta, Title } from "@/src/ui/bits"
import { entryLabel, roleLabel } from "@/src/ui/labels"
import { Screen } from "@/src/ui/screen"
import { Color, Font, Space } from "@/src/theme"

export default function Today() {
  const { actor, state, resolveQuestion } = usePocket()

  if (!actor) {
    return null
  }

  const open = state.entries
    .filter((entry) => entry.kind === EntryKind.Question && entry.question === QuestionState.Open)
    .sort((a, b) => compareWhen(b.when, a.when))

  const important = state.entries
    .filter((entry) => entry.kind === EntryKind.Important)
    .sort((a, b) => compareWhen(b.when, a.when))

  const today = state.entries
    .filter((entry) => entry.when.dayOffset === 0)
    .filter((entry) => entry.kind !== EntryKind.Important)
    .filter((entry) => !(entry.kind === EntryKind.Question && entry.question === QuestionState.Open))
    .sort((a, b) => compareWhen(b.when, a.when))

  const next = [...state.appointments]
    .filter((item) => item.when.dayOffset >= 0)
    .sort((a, b) => compareWhen(a.when, b.when))[0]

  return (
    <Screen
      footer={
        <Button label="Add update" tone={ButtonTone.Primary} onPress={() => router.push("/entry")} />
      }
    >
      <Title>Today</Title>
      <Meta>Pamela</Meta>

      <Card tone={CardTone.Ai}>
        <AiMark kind={AiKind.Summary} />
        <Body>{state.handover}</Body>
      </Card>

      <Card tone={CardTone.Soft}>
        <Meta>For the next visit</Meta>
        <Body>{state.nextVisit}</Body>
        {next ? (
          <Pressable
            accessibilityRole="button"
            onPress={() => router.push(`/appointment/${next.id}` as Href)}
          >
            <Body>
              {next.reason} · {formatWhen(next.when)}
            </Body>
            <Meta>{next.place}</Meta>
          </Pressable>
        ) : null}
      </Card>

      {open.length > 0 ? (
        <View style={styles.block}>
          <Meta>Needs an answer</Meta>
          {open.map((entry) => (
            <DiaryCard
              key={entry.id}
              entry={entry}
              canResolve={actor.role === Role.Owner}
              onResolve={() => resolveQuestion(entry.id)}
            />
          ))}
        </View>
      ) : null}

      {important.length > 0 ? (
        <View style={styles.block}>
          <Meta>Important</Meta>
          {important.map((entry) => (
            <DiaryCard key={entry.id} entry={entry} canResolve={false} onResolve={() => undefined} />
          ))}
        </View>
      ) : null}

      <View style={styles.block}>
        <Meta>Today's updates</Meta>
        {today.length === 0 ? <Body>Nothing else recorded today.</Body> : null}
        {today.map((entry) => (
          <DiaryCard key={entry.id} entry={entry} canResolve={false} onResolve={() => undefined} />
        ))}
      </View>
    </Screen>
  )
}

function DiaryCard({
  entry,
  canResolve,
  onResolve,
}: {
  entry: DiaryEntry
  canResolve: boolean
  onResolve: () => void
}) {
  return (
    <Card tone={CardTone.Soft}>
      <Meta>{entryLabel(entry.kind)}</Meta>
      <Body>{entry.body}</Body>
      {entry.attachment === Attachment.Photo ? (
        <View style={styles.photo}>
          <Text style={styles.photoText}>Photo</Text>
        </View>
      ) : null}
      {entry.voice === VoiceNote.Sample ? <Meta>Voice note</Meta> : null}
      <Meta>
        {entry.authorName}, {roleLabel(entry.authorRole)} · {formatWhen(entry.when)}
      </Meta>
      {canResolve ? <Button label="Mark resolved" tone={ButtonTone.Quiet} onPress={onResolve} /> : null}
    </Card>
  )
}

const styles = StyleSheet.create({
  block: {
    gap: Space.sm,
  },
  photo: {
    height: 72,
    borderRadius: 12,
    backgroundColor: Color.bronze,
    alignItems: "center",
    justifyContent: "center",
  },
  photoText: {
    fontFamily: Font.body,
    fontSize: 16,
    color: Color.brown,
    fontWeight: "600",
  },
})
