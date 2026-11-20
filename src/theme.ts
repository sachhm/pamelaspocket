import { Platform } from "react-native"

// Warm paper and brown ink. Body text stays on brown so olive is never small type.
export const Color = {
  brown: "#7b3e19",
  ivory: "#f8f9f0",
  petal: "#f8dbc9",
  olive: "#839073",
  bronze: "#eaac8b",
  white: "#fffcf7",
  muted: "rgba(123, 62, 25, 0.72)",
} as const

export const Space = {
  xs: 8,
  sm: 12,
  md: 16,
  lg: 24,
  xl: 32,
} as const

export const Font = {
  title: Platform.select({
    ios: "Georgia",
    android: "serif",
    web: "Georgia, Palatino, serif",
    default: "serif",
  }),
  body: Platform.select({
    web: "system-ui, -apple-system, sans-serif",
    default: undefined,
  }),
} as const

export const PHONE_WIDTH = 430
export const MIN_TAP = 48
