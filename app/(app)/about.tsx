import { useState } from "react"
import { View, StyleSheet } from "react-native"
import { Href, router } from "expo-router"

import { AboutTab, ButtonTone, CardTone, Role, StorySection } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Body, Button, Card, Chip, Meta, Title } from "@/src/ui/bits"
import { tabLabel } from "@/src/ui/labels"
import { Screen } from "@/src/ui/screen"
import { Space } from "@/src/theme"

const TABS = [AboutTab.Life, AboutTab.Personality, AboutTab.Routines, AboutTab.Works]

export default function About() {
  const { actor, state } = usePocket()
  const [tab, setTab] = useState(AboutTab.Life)

  if (!actor) {
    return null
  }

  const section = storySection(tab)
  const prompts = section ? state.prompts.filter((prompt) => prompt.section === section) : []
  const staff = actor.role === Role.Staff

  function continueStory() {
    const next = state.prompts.find((prompt) => !prompt.answer.trim()) ?? state.prompts[0]
    router.push(`/question?id=${next.id}` as Href)
  }

  return (
    <Screen>
      <Title>About Me</Title>
      <Meta>Pamela, in her own story.</Meta>
      <View style={styles.tabs}>
        {TABS.map((item) => (
          <Chip key={item} label={tabLabel(item)} selected={tab === item} onPress={() => setTab(item)} />
        ))}
      </View>

      {tab === AboutTab.Life && !staff ? (
        <View style={styles.actions}>
          <Button label="Life timeline" tone={ButtonTone.Quiet} onPress={() => router.push("/timeline")} />
          <Button label="Continue the story" tone={ButtonTone.Primary} onPress={continueStory} />
        </View>
      ) : null}

      {tab === AboutTab.Life && staff ? (
        <Button label="Life timeline" tone={ButtonTone.Quiet} onPress={() => router.push("/timeline")} />
      ) : null}

      {section
        ? prompts.map((prompt) => (
            <Card key={prompt.id} tone={CardTone.Soft}>
              <Meta>{prompt.ask}</Meta>
              <Body>{prompt.answer || "Not answered yet."}</Body>
            </Card>
          ))
        : null}

      {tab === AboutTab.Works
        ? state.works.map((card) => (
            <Card key={card.id} tone={CardTone.Soft}>
              <Meta>Situation</Meta>
              <Body>{card.situation}</Body>
              <Button
                label="Open"
                tone={ButtonTone.Quiet}
                onPress={() => router.push(`/works/${card.id}` as Href)}
              />
            </Card>
          ))
        : null}
    </Screen>
  )
}

function storySection(tab: AboutTab): StorySection | null {
  if (tab === AboutTab.Life) {
    return StorySection.Life
  }

  if (tab === AboutTab.Personality) {
    return StorySection.Personality
  }

  if (tab === AboutTab.Routines) {
    return StorySection.Routines
  }

  return null
}

const styles = StyleSheet.create({
  tabs: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Space.sm,
  },
  actions: {
    gap: Space.sm,
  },
})
