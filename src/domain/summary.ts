import { compareWhen } from "@/src/domain/time"
import { DiaryEntry } from "@/src/domain/types"

const RECENT_NOTES = 3
const REPORT_SENTENCES = 2

// Joins notes Pamela already has. It does not add a fact that is not in the diary.
export function summariseDiary(entries: DiaryEntry[]): string {
  const recent = [...entries].sort((a, b) => compareWhen(b.when, a.when)).slice(0, RECENT_NOTES)

  if (recent.length === 0) {
    return "No notes yet."
  }

  return recent.map((entry) => entry.body.replace(/\s+/g, " ").trim()).join(" ")
}

export function summariseReport(original: string): string {
  const sentences = original
    .split(/(?<=\.)\s+/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
    .slice(0, REPORT_SENTENCES)

  if (sentences.length === 0) {
    return "The report has no text to summarise."
  }

  return sentences.join(" ")
}
