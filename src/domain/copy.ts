import { Attachment, NewEntry, RequestKind, VoiceNote } from "@/src/domain/types"

export const SAMPLE_VOICE = "She said the lemons from Joan were the best this year."

const PHOTO_ONLY = "Photo from the visit."

export function requestText(kind: RequestKind): string {
  if (kind === RequestKind.Appointment) {
    return "Can someone take Mum to her appointment?"
  }

  if (kind === RequestKind.Visit) {
    return "Who can visit this weekend?"
  }

  return "Can someone collect a prescription?"
}

// Voice and photo can stand in for a typed note in the demo.
export function composeBody(input: Pick<NewEntry, "body" | "voice" | "attachment">): string {
  const trimmed = input.body.trim()

  if (input.voice === VoiceNote.Sample && trimmed.includes(SAMPLE_VOICE)) {
    return trimmed
  }

  if (input.voice === VoiceNote.Sample && trimmed) {
    return `${trimmed}\n\n${SAMPLE_VOICE}`
  }

  if (input.voice === VoiceNote.Sample) {
    return SAMPLE_VOICE
  }

  if (trimmed) {
    return trimmed
  }

  if (input.attachment === Attachment.Photo) {
    return PHOTO_ONLY
  }

  return ""
}
