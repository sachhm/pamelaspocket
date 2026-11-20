import { DEMO_PIN } from "@/src/domain/auth"
import { AccessState, ButtonTone, CardTone, Role } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Body, Button, Card, Meta } from "@/src/ui/bits"
import { Guard } from "@/src/ui/guard"
import { roleLabel } from "@/src/ui/labels"
import { QrMark } from "@/src/ui/qr"
import { Screen } from "@/src/ui/screen"

export default function Access() {
  return (
    <Guard roles={[Role.Owner]}>
      <AccessPage />
    </Guard>
  )
}

function AccessPage() {
  const { state, revokeAccess, restoreAccess } = usePocket()
  const active = state.access === AccessState.Active

  return (
    <Screen title="Access">
      <Body>Staff scan this code, pick their name, then enter the PIN.</Body>
      <QrMark />
      <Card tone={CardTone.Soft}>
        <Meta>Staff PIN</Meta>
        <Body>{DEMO_PIN}</Body>
        <Meta>{active ? "Access is on." : "Access is off. The PIN will be refused."}</Meta>
      </Card>
      <Button
        label={active ? "Turn off access" : "Turn access back on"}
        tone={active ? ButtonTone.Quiet : ButtonTone.Primary}
        onPress={active ? revokeAccess : restoreAccess}
      />
      <Meta>People</Meta>
      {state.people.map((person) => (
        <Card key={person.name} tone={CardTone.Soft}>
          <Body>{person.name}</Body>
          <Meta>{roleLabel(person.role)}</Meta>
        </Card>
      ))}
    </Screen>
  )
}
