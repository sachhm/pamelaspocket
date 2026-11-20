import { router } from "expo-router"

import { ButtonTone } from "@/src/domain/types"
import { Button, Body, Title } from "@/src/ui/bits"
import { Screen } from "@/src/ui/screen"

export default function NotFound() {
  return (
    <Screen>
      <Title>That page is not here</Title>
      <Body>Pamela's Pocket only has the care diary, her story, chat, family, and settings.</Body>
      <Button label="Back to the start" tone={ButtonTone.Primary} onPress={() => router.replace("/")} />
    </Screen>
  )
}
