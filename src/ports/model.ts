import { Answer, DiaryEntry } from "@/src/domain/types"

// Language calls. The local adapter repeats Pamela's notes and does not invent clinical facts.
export interface ModelPort {
  answerCare(text: string, entries: DiaryEntry[]): Promise<Answer>
  guideReply(spokenCount: number): Promise<string>
  summariseDiary(entries: DiaryEntry[]): Promise<string>
  summariseReport(original: string): Promise<string>
}
