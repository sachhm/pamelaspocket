import { answerCare, guideReply } from "@/src/domain/chat"
import { summariseDiary, summariseReport } from "@/src/domain/summary"
import { DiaryEntry } from "@/src/domain/types"
import { ModelPort } from "@/src/ports/model"

export class LocalModel implements ModelPort {
  async answerCare(text: string, entries: DiaryEntry[]) {
    return answerCare(text, entries)
  }

  async guideReply(spokenCount: number) {
    return guideReply(spokenCount)
  }

  async summariseDiary(entries: DiaryEntry[]) {
    return summariseDiary(entries)
  }

  async summariseReport(original: string) {
    return summariseReport(original)
  }
}
