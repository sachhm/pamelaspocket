import { StyleSheet, Text, View } from "react-native"

import { usePocket } from "@/src/session/pocket"
import { Body, Meta } from "@/src/ui/bits"
import { Screen } from "@/src/ui/screen"
import { Color, Font, Space } from "@/src/theme"

export default function Timeline() {
  const { state } = usePocket()
  const beats = state.prompts
    .filter((prompt) => prompt.year)
    .sort((a, b) => Number(a.year) - Number(b.year))

  return (
    <Screen title="Life timeline">
      <Meta>Built from Pamela's story. Photo spaces are empty in this demo.</Meta>
      {beats.map((beat, index) => (
        <View key={beat.id} style={styles.row}>
          <View style={styles.rail}>
            <View style={styles.dot} />
            {index < beats.length - 1 ? <View style={styles.line} /> : null}
          </View>
          <View style={styles.copy}>
            <View style={styles.photo}>
              <Text style={styles.year}>{beat.year}</Text>
            </View>
            <Body>{beat.answer}</Body>
          </View>
        </View>
      ))}
    </Screen>
  )
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    gap: Space.md,
  },
  rail: {
    width: 16,
    alignItems: "center",
  },
  dot: {
    width: 14,
    height: 14,
    borderRadius: 7,
    backgroundColor: Color.brown,
    marginTop: 8,
  },
  line: {
    width: 2,
    flex: 1,
    backgroundColor: Color.bronze,
    marginTop: 4,
  },
  copy: {
    flex: 1,
    gap: Space.xs,
    paddingBottom: Space.md,
  },
  photo: {
    height: 72,
    borderRadius: 12,
    backgroundColor: Color.petal,
    alignItems: "center",
    justifyContent: "center",
  },
  year: {
    fontFamily: Font.title,
    fontSize: 22,
    color: Color.brown,
  },
})
