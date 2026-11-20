import { ReactNode } from "react"
import { Pressable, StyleSheet, Text, TextInput, View } from "react-native"

import {
  AiKind,
  ButtonTone,
  CardTone,
  FieldPrivacy,
  FieldSize,
} from "@/src/domain/types"
import { Color, Font, MIN_TAP, Space } from "@/src/theme"

export function Title({ children }: { children: string }) {
  return <Text style={styles.title}>{children}</Text>
}

export function Body({ children }: { children: ReactNode }) {
  return <Text style={styles.body}>{children}</Text>
}

export function Meta({ children }: { children: ReactNode }) {
  return <Text style={styles.meta}>{children}</Text>
}

export function AiMark({ kind }: { kind: AiKind }) {
  const label = kind === AiKind.Reply ? "AI" : "AI summary"

  return <Text style={styles.ai}>{label}</Text>
}

export function Button({
  label,
  tone,
  onPress,
  disabled,
}: {
  label: string
  tone: ButtonTone
  onPress: () => void
  disabled?: boolean
}) {
  const quiet = tone === ButtonTone.Quiet

  function handlePress() {
    if (disabled) {
      return
    }

    onPress()
  }

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: !!disabled }}
      onPress={handlePress}
      style={[styles.button, quiet ? styles.quiet : styles.primary, disabled && styles.disabled]}
    >
      <Text style={[styles.buttonText, quiet ? styles.quietText : styles.primaryText]}>{label}</Text>
    </Pressable>
  )
}

export function Chip({
  label,
  selected,
  onPress,
}: {
  label: string
  selected: boolean
  onPress: () => void
}) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={[styles.chip, selected && styles.chipOn]}
    >
      <Text style={[styles.chipText, selected && styles.chipTextOn]}>{label}</Text>
    </Pressable>
  )
}

export function Card({
  children,
  tone,
}: {
  children: ReactNode
  tone: CardTone
}) {
  return <View style={[styles.card, toneStyle(tone)]}>{children}</View>
}

function toneStyle(tone: CardTone) {
  if (tone === CardTone.Ai) {
    return styles.cardAi
  }

  if (tone === CardTone.Note) {
    return styles.cardNote
  }

  return styles.cardSoft
}

export function Field({
  label,
  value,
  onChange,
  privacy,
  size,
  hint,
}: {
  label: string
  value: string
  onChange: (value: string) => void
  privacy: FieldPrivacy
  size: FieldSize
  hint?: string
}) {
  const story = size === FieldSize.Story

  return (
    <View style={styles.field}>
      <Text style={styles.fieldLabel}>{label}</Text>
      <TextInput
        value={value}
        onChangeText={onChange}
        secureTextEntry={privacy === FieldPrivacy.Secret}
        multiline={story}
        autoCapitalize={privacy === FieldPrivacy.Secret ? "none" : "sentences"}
        autoCorrect={privacy === FieldPrivacy.Public}
        placeholder={hint}
        placeholderTextColor={Color.muted}
        style={[styles.input, story && styles.story]}
      />
    </View>
  )
}

const styles = StyleSheet.create({
  title: {
    fontFamily: Font.title,
    fontSize: 32,
    lineHeight: 38,
    color: Color.brown,
  },
  body: {
    fontFamily: Font.body,
    fontSize: 18,
    lineHeight: 26,
    color: Color.brown,
  },
  meta: {
    fontFamily: Font.body,
    fontSize: 15,
    lineHeight: 21,
    color: Color.muted,
  },
  ai: {
    fontFamily: Font.body,
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "700",
    letterSpacing: 0.3,
    color: Color.olive,
    textTransform: "uppercase",
  },
  button: {
    minHeight: 52,
    borderRadius: 14,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 18,
    paddingVertical: 12,
    cursor: "pointer",
  },
  primary: {
    backgroundColor: Color.brown,
  },
  quiet: {
    backgroundColor: Color.bronze,
  },
  disabled: {
    opacity: 0.45,
  },
  buttonText: {
    fontFamily: Font.body,
    fontSize: 18,
    fontWeight: "600",
  },
  primaryText: {
    color: Color.ivory,
  },
  quietText: {
    color: Color.brown,
  },
  chip: {
    minHeight: MIN_TAP,
    borderRadius: 999,
    paddingHorizontal: 14,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: Color.bronze,
    cursor: "pointer",
  },
  chipOn: {
    backgroundColor: Color.brown,
  },
  chipText: {
    fontFamily: Font.body,
    fontSize: 16,
    color: Color.brown,
  },
  chipTextOn: {
    color: Color.ivory,
  },
  card: {
    borderRadius: 16,
    padding: Space.md,
    gap: Space.xs,
  },
  cardSoft: {
    backgroundColor: Color.petal,
  },
  cardNote: {
    backgroundColor: Color.bronze,
  },
  cardAi: {
    backgroundColor: Color.white,
    borderLeftWidth: 4,
    borderLeftColor: Color.olive,
  },
  field: {
    gap: Space.xs,
  },
  fieldLabel: {
    fontFamily: Font.body,
    fontSize: 16,
    color: Color.brown,
    fontWeight: "600",
  },
  input: {
    fontFamily: Font.body,
    fontSize: 18,
    color: Color.brown,
    backgroundColor: Color.white,
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    minHeight: MIN_TAP,
  },
  story: {
    minHeight: 140,
    textAlignVertical: "top",
  },
})
