import { Redirect, router } from "expo-router"

import { ButtonTone } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Body, Button, Meta, Title } from "@/src/ui/bits"
import { Screen } from "@/src/ui/screen"

export default function Welcome() {
  const { actor } = usePocket()

  if (actor) {
    return <Redirect href="/today" />
  }

  return (
    <Screen>
      <Title>Pamela's Pocket</Title>
      <Body>A shared diary for the people who care for Pamela.</Body>
      <Button
        label="I'm the primary carer"
        tone={ButtonTone.Primary}
        onPress={() => router.push("/sign-in?role=owner")}
      />
      <Button label="I'm staff" tone={ButtonTone.Quiet} onPress={() => router.push("/pin")} />
      <Button
        label="I'm family"
        tone={ButtonTone.Quiet}
        onPress={() => router.push("/sign-in?role=family")}
      />
      <Meta>This is a demo. Nothing is sent to a server.</Meta>
    </Screen>
  )
}
