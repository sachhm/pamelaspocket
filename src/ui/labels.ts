import { AboutTab, EntryKind, Role } from "@/src/domain/types"

export function roleLabel(role: Role): string {
  if (role === Role.Owner) {
    return "Primary carer"
  }

  if (role === Role.Family) {
    return "Family"
  }

  return "Staff"
}

export function entryLabel(kind: EntryKind): string {
  if (kind === EntryKind.General) {
    return "General update"
  }

  if (kind === EntryKind.Mood) {
    return "Mood or behaviour"
  }

  if (kind === EntryKind.Important) {
    return "Something important"
  }

  if (kind === EntryKind.Question) {
    return "Question or concern"
  }

  return "A lovely moment"
}

export function tabLabel(tab: AboutTab): string {
  if (tab === AboutTab.Life) {
    return "Life"
  }

  if (tab === AboutTab.Personality) {
    return "Personality"
  }

  if (tab === AboutTab.Routines) {
    return "Routines"
  }

  return "What works"
}
