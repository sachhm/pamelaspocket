import Ionicons from "@expo/vector-icons/Ionicons"
import { Redirect, Tabs } from "expo-router"
import { ColorValue } from "react-native"

import { Role } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Color } from "@/src/theme"

function ink(color: ColorValue): string {
  if (typeof color === "string") {
    return color
  }

  return Color.brown
}

export default function TabLayout() {
  const { actor } = usePocket()

  if (!actor) {
    return <Redirect href="/" />
  }

  const staff = actor.role === Role.Staff

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: Color.brown,
        tabBarInactiveTintColor: Color.olive,
        tabBarStyle: {
          backgroundColor: Color.ivory,
          borderTopColor: Color.bronze,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: "600",
        },
      }}
    >
      <Tabs.Screen
        name="today"
        options={{
          title: "Today",
          tabBarIcon: ({ color, size }) => <Ionicons name="sunny-outline" color={ink(color)} size={size} />,
        }}
      />
      <Tabs.Screen
        name="about"
        options={{
          title: "About Me",
          tabBarIcon: ({ color, size }) => <Ionicons name="person-outline" color={ink(color)} size={size} />,
        }}
      />
      <Tabs.Screen
        name="chat"
        options={{
          title: "Chat",
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="chatbubble-ellipses-outline" color={ink(color)} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="family"
        options={{
          title: "Family",
          // Staff do not share the family help board.
          href: staff ? null : "/family",
          tabBarIcon: ({ color, size }) => <Ionicons name="people-outline" color={ink(color)} size={size} />,
        }}
      />
      <Tabs.Screen
        name="more"
        options={{
          title: "More",
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="ellipsis-horizontal" color={ink(color)} size={size} />
          ),
        }}
      />
    </Tabs>
  )
}
