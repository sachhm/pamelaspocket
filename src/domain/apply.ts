import { Escalation, PocketState, QuestionState } from "@/src/domain/types"
import { CareCommand } from "@/src/ports/records"

// Pure transitions. Adapters persist the result; they do not reimplement the rules.
export function applyCommand(state: PocketState, command: CareCommand): PocketState {
  if (command.kind === "entry.add") {
    return {
      ...state,
      tick: Math.max(state.tick, command.entry.when.seq),
      entries: [command.entry, ...state.entries],
    }
  }

  if (command.kind === "question.resolve") {
    return {
      ...state,
      entries: state.entries.map((entry) => {
        if (entry.id !== command.id) {
          return entry
        }

        return { ...entry, question: QuestionState.Resolved }
      }),
    }
  }

  if (command.kind === "answer.save") {
    return {
      ...state,
      prompts: state.prompts.map((prompt) => {
        if (prompt.id !== command.id) {
          return prompt
        }

        return { ...prompt, answer: command.text }
      }),
    }
  }

  if (command.kind === "observation.add") {
    return {
      ...state,
      works: state.works.map((card) => {
        if (card.id !== command.worksId) {
          return card
        }

        return { ...card, observations: [...card.observations, command.line] }
      }),
    }
  }

  if (command.kind === "messages.add") {
    const last = command.notes[command.notes.length - 1]

    return {
      ...state,
      tick: last ? Math.max(state.tick, last.when.seq) : state.tick,
      messages: [...state.messages, ...command.notes],
    }
  }

  if (command.kind === "message.sent") {
    return {
      ...state,
      tick: Math.max(state.tick, command.note.when.seq),
      messages: state.messages
        .map((item) => {
          if (item.id !== command.id) {
            return item
          }

          return { ...item, escalation: Escalation.Sent }
        })
        .concat(command.note),
    }
  }

  if (command.kind === "help.accept") {
    return {
      ...state,
      requests: state.requests.map((item) => {
        if (item.id !== command.id || item.acceptedBy) {
          return item
        }

        return { ...item, acceptedBy: command.name }
      }),
    }
  }

  if (command.kind === "help.post") {
    return { ...state, requests: [command.request, ...state.requests] }
  }

  if (command.kind === "reminder.set") {
    return {
      ...state,
      appointments: state.appointments.map((item) => {
        if (item.id !== command.id) {
          return item
        }

        return { ...item, reminder: command.reminder }
      }),
    }
  }

  if (command.kind === "volunteer.set") {
    return {
      ...state,
      appointments: state.appointments.map((item) => {
        if (item.id !== command.id || item.volunteer) {
          return item
        }

        return { ...item, volunteer: command.name }
      }),
    }
  }

  if (command.kind === "handover.set") {
    return { ...state, handover: command.text }
  }

  if (command.kind === "access.set") {
    return { ...state, access: command.access }
  }

  if (command.kind === "report.add") {
    return {
      ...state,
      tick: Math.max(state.tick, command.report.when.seq),
      reports: [command.report, ...state.reports],
    }
  }

  const missed: never = command

  return missed
}
