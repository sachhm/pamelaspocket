import { useState } from "react"
import { Pressable, StyleSheet, Text, View } from "react-native"
import { Redirect } from "expo-router"

import { DEMO_PIN, PIN_LENGTH, STAFF_NAMES } from "@/src/domain/auth"
import { AccessState, ButtonTone, PinResult } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Body, Button, Chip, Meta, Title } from "@/src/ui/bits"
import { QrMark } from "@/src/ui/qr"
import { Screen } from "@/src/ui/screen"
import { Color, Font, MIN_TAP, Space } from "@/src/theme"

const KEYS = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "del"]

export default function Pin() {
  const { actor, state, enterStaff } = usePocket()
  const [name, setName] = useState<(typeof STAFF_NAMES)[number]>("Jordan")
  const [pin, setPin] = useState("")
  const [error, setError] = useState("")

  if (actor) {
    return <Redirect href="/today" />
  }

  async function submit(code: string) {
    try {
      const result = await enterStaff(code, name)

      if (result === PinResult.Ok) {
        return
      }

      if (result === PinResult.Revoked) {
        setError("This code has been turned off. Ask Alex to turn it back on.")
      } else {
        setError("That PIN is not right.")
      }
    } catch {
      setError("The access service did not answer.")
    }

    setPin("")
  }

  function onKey(key: string) {
    if (!key) {
      return
    }

    setError("")

    if (key === "del") {
      setPin((current) => current.slice(0, -1))
      return
    }

    if (pin.length >= PIN_LENGTH) {
      return
    }

    const next = `${pin}${key}`
    setPin(next)

    if (next.length === PIN_LENGTH) {
      submit(next)
    }
  }

  const revoked = state.access === AccessState.Revoked

  return (
    <Screen title="Staff access">
      <Title>Pamela's code</Title>
      <QrMark />
      {revoked ? <Body>Access is off until Alex turns it back on.</Body> : null}
      <Meta>Who is on this shift?</Meta>
      <View style={styles.names}>
        {STAFF_NAMES.map((staff) => (
          <Chip key={staff} label={staff} selected={name === staff} onPress={() => setName(staff)} />
        ))}
      </View>
      <View style={styles.dots}>
        {Array.from({ length: PIN_LENGTH }, (_, index) => (
          <View key={index} style={[styles.dot, index < pin.length && styles.dotOn]} />
        ))}
      </View>
      <View style={styles.pad}>
        {KEYS.map((key, index) =>
          key ? (
            <Pressable key={key} accessibilityRole="button" onPress={() => onKey(key)} style={styles.key}>
              <Text style={styles.keyText}>{key === "del" ? "Delete" : key}</Text>
            </Pressable>
          ) : (
            <View key={`gap-${index}`} style={styles.key} />
          ),
        )}
      </View>
      {error ? <Body>{error}</Body> : null}
      <Button
        label="Enter"
        tone={ButtonTone.Primary}
        onPress={() => submit(pin)}
        disabled={pin.length !== PIN_LENGTH}
      />
      <Meta>Demo PIN {DEMO_PIN}</Meta>
    </Screen>
  )
}

const styles = StyleSheet.create({
  names: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Space.sm,
  },
  dots: {
    flexDirection: "row",
    justifyContent: "center",
    gap: Space.md,
  },
  dot: {
    width: 16,
    height: 16,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: Color.brown,
  },
  dotOn: {
    backgroundColor: Color.brown,
  },
  pad: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Space.sm,
    justifyContent: "center",
  },
  key: {
    width: 88,
    minHeight: MIN_TAP + 8,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: Color.petal,
    cursor: "pointer",
  },
  keyText: {
    fontFamily: Font.body,
    fontSize: 22,
    color: Color.brown,
    fontWeight: "600",
  },
})
