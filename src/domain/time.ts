import { When } from "@/src/domain/types"

export function whenToDate(when: When): Date {
  const date = new Date()

  date.setDate(date.getDate() + when.dayOffset)
  date.setHours(when.hour, when.minute, 0, 0)

  return date
}

export function compareWhen(a: When, b: When): number {
  const delta = whenToDate(a).getTime() - whenToDate(b).getTime()

  if (delta !== 0) {
    return delta
  }

  return a.seq - b.seq
}

export function formatWhen(when: When): string {
  const date = whenToDate(when)
  const time = date.toLocaleTimeString("en-AU", { hour: "numeric", minute: "2-digit" })

  if (when.dayOffset === 0) {
    return `Today, ${time}`
  }

  if (when.dayOffset === -1) {
    return `Yesterday, ${time}`
  }

  const day = date.toLocaleDateString("en-AU", {
    weekday: "short",
    day: "numeric",
    month: "short",
  })

  return `${day}, ${time}`
}

// seq breaks ties when two notes land in the same minute.
export function stampNow(tick: number): { tick: number; when: When } {
  const now = new Date()
  const next = tick + 1

  return {
    tick: next,
    when: {
      dayOffset: 0,
      hour: now.getHours(),
      minute: now.getMinutes(),
      seq: next,
    },
  }
}

export function makeId(prefix: string): string {
  const time = Date.now().toString(36)
  const noise = Math.floor(Math.random() * 1000).toString(36)

  return `${prefix}-${time}-${noise}`
}
