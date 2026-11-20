import { router } from "expo-router"

import { requestText } from "@/src/domain/copy"
import { ButtonTone, RequestKind, Role } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Body, Button, Meta } from "@/src/ui/bits"
import { Guard } from "@/src/ui/guard"
import { Screen } from "@/src/ui/screen"

const KINDS = [RequestKind.Appointment, RequestKind.Visit, RequestKind.Prescription]

export default function Request() {
  return (
    <Guard roles={[Role.Owner]}>
      <RequestForm />
    </Guard>
  )
}

function RequestForm() {
  const { postRequest } = usePocket()

  function onPost(kind: RequestKind) {
    postRequest(kind)
    router.back()
  }

  return (
    <Screen title="Ask for help">
      <Body>Post one clear ask. Anyone in the family can say they will take it.</Body>
      <Meta>No roster. No assignments.</Meta>
      {KINDS.map((kind) => (
        <Button key={kind} label={requestText(kind)} tone={ButtonTone.Primary} onPress={() => onPost(kind)} />
      ))}
    </Screen>
  )
}
