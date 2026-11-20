import { View, StyleSheet } from "react-native"
import { Stack } from "expo-router"
import { SafeAreaProvider } from "react-native-safe-area-context"

import { PocketProvider } from "@/src/session/pocket"
import { Color, PHONE_WIDTH } from "@/src/theme"

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <View style={styles.outer}>
        <View style={styles.frame}>
          <PocketProvider>
            <Stack
              screenOptions={{
                headerShown: false,
                contentStyle: { backgroundColor: Color.ivory },
              }}
            >
              <Stack.Screen name="entry" options={{ presentation: "modal" }} />
            </Stack>
          </PocketProvider>
        </View>
      </View>
    </SafeAreaProvider>
  )
}

const styles = StyleSheet.create({
  outer: {
    flex: 1,
    backgroundColor: Color.petal,
    alignItems: "center",
  },
  frame: {
    flex: 1,
    width: "100%",
    maxWidth: PHONE_WIDTH,
    backgroundColor: Color.ivory,
  },
})
