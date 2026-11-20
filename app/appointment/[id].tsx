import { useLocalSearchParams } from "expo-router"

import { formatWhen } from "@/src/domain/time"
import { ButtonTone, CardTone, Reminder, Role } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Body, Button, Card, Meta } from "@/src/ui/bits"
import { Screen } from "@/src/ui/screen"

export default function Appointment() {
  const { actor, state, toggleReminder, volunteer } = usePocket()
  const params = useLocalSearchParams<{ id: string }>()
  const raw = Array.isArray(params.id) ? params.id[0] : params.id
  const item = state.appointments.find((appointment) => appointment.id === raw)
  const canOffer = actor?.role !== Role.Staff

  if (!item) {
    return (
      <Screen title="Appointment">
        <Body>That appointment is not on the list.</Body>
      </Screen>
    )
  }

  const reminderLabel = item.reminder === Reminder.On ? "Reminder on" : "Reminder off"

  return (
    <Screen title="Appointment">
      <Card tone={CardTone.Soft}>
        <Body>{item.reason}</Body>
        <Meta>{formatWhen(item.when)}</Meta>
        <Meta>{item.place}</Meta>
        <Meta>{item.transport}</Meta>
        <Body>{item.notes}</Body>
      </Card>
      {item.volunteer ? <Meta>{item.volunteer} can help with the trip.</Meta> : null}
      {canOffer && !item.volunteer ? (
        <Button label="I can help" tone={ButtonTone.Primary} onPress={() => volunteer(item.id)} />
      ) : null}
      {canOffer ? (
        <Button label={reminderLabel} tone={ButtonTone.Quiet} onPress={() => toggleReminder(item.id)} />
      ) : (
        <Meta>{reminderLabel}</Meta>
      )}
      <Meta>This is a note, not a calendar booking. The reminder stays on this device.</Meta>
    </Screen>
  )
}
