import { StyleSheet, View } from "react-native"

import { Color } from "@/src/theme"

const CELLS = 21
const FINDER = 7

// A drawn stand-in so the demo needs no image asset. It is not a scannable code.
export function QrMark() {
  return (
    <View
      accessibilityRole="image"
      accessibilityLabel="Demo code for Pamela's care profile"
      style={styles.pad}
    >
      {Array.from({ length: CELLS }, (_, row) => (
        <View key={row} style={styles.row}>
          {Array.from({ length: CELLS }, (_, col) => (
            <View key={col} style={[styles.cell, cellOn(row, col) && styles.on]} />
          ))}
        </View>
      ))}
    </View>
  )
}

function cellOn(row: number, col: number): boolean {
  const local = finderLocal(row, col)

  if (local) {
    return finderOn(local.row, local.col)
  }

  return (row * 3 + col * 5) % 4 === 0
}

function finderLocal(row: number, col: number): { row: number; col: number } | null {
  const origins = [
    { row: 0, col: 0 },
    { row: 0, col: CELLS - FINDER },
    { row: CELLS - FINDER, col: 0 },
  ]

  for (const origin of origins) {
    const localRow = row - origin.row
    const localCol = col - origin.col
    const inside = localRow >= 0 && localCol >= 0 && localRow < FINDER && localCol < FINDER

    if (inside) {
      return { row: localRow, col: localCol }
    }
  }

  return null
}

function finderOn(row: number, col: number): boolean {
  const edge = row === 0 || col === 0 || row === FINDER - 1 || col === FINDER - 1
  const core = row >= 2 && row <= 4 && col >= 2 && col <= 4

  return edge || core
}

const CELL = 8

const styles = StyleSheet.create({
  pad: {
    alignSelf: "center",
    backgroundColor: Color.white,
    padding: 10,
    borderRadius: 12,
  },
  row: {
    flexDirection: "row",
  },
  cell: {
    width: CELL,
    height: CELL,
    backgroundColor: Color.white,
  },
  on: {
    backgroundColor: Color.brown,
  },
})
