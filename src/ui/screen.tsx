import { ReactNode } from "react"
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native"
import { router } from "expo-router"

import { Color, Font, MIN_TAP, Space } from "@/src/theme"

export function Screen({
  title,
  children,
  footer,
}: {
  title?: string
  children: ReactNode
  footer?: ReactNode
}) {
  return (
    <View style={styles.root}>
      {title ? <TopBar title={title} /> : null}
      <ScrollView
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={styles.body}
      >
        {children}
      </ScrollView>
      {footer ? <View style={styles.footer}>{footer}</View> : null}
    </View>
  )
}

export function TopBar({ title }: { title: string }) {
  return (
    <View style={styles.bar}>
      <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.back}>
        <Text style={styles.backText}>Back</Text>
      </Pressable>
      <Text style={styles.barTitle} numberOfLines={1}>
        {title}
      </Text>
    </View>
  )
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: Color.ivory,
  },
  body: {
    padding: Space.lg,
    gap: Space.md,
    paddingBottom: Space.xl,
  },
  footer: {
    paddingHorizontal: Space.lg,
    paddingTop: Space.sm,
    paddingBottom: Space.lg,
    gap: Space.sm,
    backgroundColor: Color.ivory,
  },
  bar: {
    paddingHorizontal: Space.lg,
    paddingTop: Space.md,
    paddingBottom: Space.sm,
    gap: 2,
  },
  back: {
    minHeight: MIN_TAP,
    justifyContent: "center",
    alignSelf: "flex-start",
    cursor: "pointer",
  },
  backText: {
    fontFamily: Font.body,
    fontSize: 18,
    color: Color.brown,
    fontWeight: "600",
  },
  barTitle: {
    fontFamily: Font.title,
    fontSize: 28,
    lineHeight: 34,
    color: Color.brown,
  },
})
