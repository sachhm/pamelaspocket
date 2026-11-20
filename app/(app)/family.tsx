import { Href, router } from "expo-router"
import { View, StyleSheet } from "react-native"

import { compareWhen, formatWhen } from "@/src/domain/time"
import { ButtonTone, CardTone, EntryKind, Reminder, Role } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Body, Button, Card, Meta, Title } from "@/src/ui/bits"
import { Guard } from "@/src/ui/guard"
import { Screen } from "@/src/ui/screen"
import { Space } from "@/src/theme"

export default function Family() {
  return (
    <Guard roles={[Role.Owner, Role.Family]}>
      <FamilyBoard />
    </Guard>
  )
}

function FamilyBoard() {
  const { actor, state, acceptHelp } = usePocket()

  if (!actor) {
    return null
  }

  const recent = [...state.entries].sort((a, b) => compareWhen(b.when, a.when)).slice(0, 2)
  const moment = [...state.entries]
    .filter((entry) => entry.kind === EntryKind.Moment)
    .sort((a, b) => compareWhen(b.when, a.when))[0]
  const upcoming = [...state.appointments]
    .filter((item) => item.when.dayOffset >= 0)
    .sort((a, b) => compareWhen(a.when, b.when))

  return (
    <Screen>
      <Title>Family</Title>
      <Card tone={CardTone.Soft}>
        <Meta>How Pamela has been</Meta>
        <Body>{state.familyStatus}</Body>
      </Card>

      {moment ? (
        <Card tone={CardTone.Note}>
          <Meta>A lovely moment</Meta>
          <Body>{moment.body}</Body>
          <Meta>{moment.authorName}</Meta>
        </Card>
      ) : null}

      <View style={styles.block}>
        <Meta>Recent updates</Meta>
        {recent.map((entry) => (
          <Card key={entry.id} tone={CardTone.Soft}>
            <Body>{entry.body}</Body>
            <Meta>
              {entry.authorName} · {formatWhen(entry.when)}
            </Meta>
          </Card>
        ))}
      </View>

      <View style={styles.block}>
        <Meta>Coming up</Meta>
        {upcoming.map((item) => (
          <Card key={item.id} tone={CardTone.Soft}>
            <Body>{item.reason}</Body>
            <Meta>
              {formatWhen(item.when)} · {item.place}
            </Meta>
            <Meta>{item.transport}</Meta>
            {item.reminder === Reminder.On ? <Meta>Reminder on</Meta> : null}
            <Button
              label="Open"
              tone={ButtonTone.Quiet}
              onPress={() => router.push(`/appointment/${item.id}` as Href)}
            />
          </Card>
        ))}
      </View>

      <View style={styles.block}>
        <Meta>Where help would matter</Meta>
        {actor.role === Role.Owner ? (
          <Button label="Ask for help" tone={ButtonTone.Primary} onPress={() => router.push("/request")} />
        ) : null}
        {state.requests.map((item) => (
          <Card key={item.id} tone={CardTone.Soft}>
            <Body>{item.text}</Body>
            {item.acceptedBy ? <Meta>{item.acceptedBy} can help</Meta> : null}
            {!item.acceptedBy ? (
              <Button label="I can help" tone={ButtonTone.Quiet} onPress={() => acceptHelp(item.id)} />
            ) : null}
          </Card>
        ))}
      </View>
    </Screen>
  )
}

const styles = StyleSheet.create({
  block: {
    gap: Space.sm,
  },
})
