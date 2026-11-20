import { Answer, DiaryEntry, Known } from "@/src/domain/types"

function known(body: string): Answer {
  return { known: Known.Yes, body }
}

function unknown(body: string): Answer {
  return { known: Known.No, body }
}

function mentionsMeal(body: string): boolean {
  return /porrid|breakfast|lunch|dinner|ate|tea/.test(body.toLowerCase())
}

// Repeats Pamela's notes. If the note is missing, the answer says so.
export function answerCare(text: string, entries: DiaryEntry[]): Answer {
  const question = text.toLowerCase()

  if (question.includes("breakfast") || question.includes("porridge")) {
    return known("Pamela usually has porridge with honey, and tea with milk.")
  }

  if (question.includes("spare") || question.includes("clothes")) {
    return known("Spare clothes are in the hall cupboard, on the second shelf.")
  }

  if (question.includes("upset") || question.includes("phone")) {
    return known(
      "Step outside to take the call, and tell her calmly before you leave. Taking the call in front of her has not helped.",
    )
  }

  if (question.includes("eaten") || question.includes("eat")) {
    const meal = entries.find((entry) => entry.when.dayOffset === 0 && mentionsMeal(entry.body))

    if (!meal) {
      return unknown("I don't have that in today's notes.")
    }

    return known(meal.body)
  }

  if (question.includes("previous") || question.includes("last visit")) {
    const prior = [...entries]
      .filter((entry) => entry.when.dayOffset < 0)
      .sort((a, b) => b.when.dayOffset - a.when.dayOffset)[0]

    if (!prior) {
      return unknown("I don't have a note from the previous visit.")
    }

    return known(`${prior.authorName} wrote: ${prior.body}`)
  }

  return unknown("I don't have that in Pamela's notes.")
}

const GUIDE_REPLIES = [
  "That sounds like a heavy moment. You don't have to solve all of it tonight.",
  "You're allowed to find this hard. What would make the next hour a little easier?",
  "Thank you for saying it plainly. None of this is added to the shared diary.",
]

export function guideReply(count: number): string {
  const index = count % GUIDE_REPLIES.length

  return GUIDE_REPLIES[index]
}
