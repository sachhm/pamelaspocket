import { composeBody, requestText } from "@/src/domain/copy"
import { makeId, stampNow } from "@/src/domain/time"
import {
  AccessState,
  Actor,
  Attachment,
  DiaryEntry,
  EntryKind,
  Escalation,
  Known,
  MessageSource,
  NewEntry,
  NewReport,
  Note,
  PocketState,
  QuestionState,
  Reminder,
  RequestKind,
  Role,
  Thread,
  VoiceNote,
} from "@/src/domain/types"
import { CarePorts } from "@/src/ports/bundle"
import { AuthOutcome, StaffOutcome } from "@/src/ports/auth"
import { FileKind } from "@/src/ports/files"

enum Gate {
  Any = "any",
  Household = "household",
  Owner = "owner",
}

type Held = {
  actor: Actor
  state: PocketState
}

function passes(actor: Actor, gate: Gate): boolean {
  if (gate === Gate.Owner) {
    return actor.role === Role.Owner
  }

  if (gate === Gate.Household) {
    return actor.role !== Role.Staff
  }

  return true
}

// Use cases. Screens never call a port. Swap ports in compose.ts.
export class CareDesk {
  private tail: Promise<void> = Promise.resolve()

  constructor(private readonly ports: CarePorts) {}

  load() {
    return this.step(async () => {
      const [actor, state] = await Promise.all([this.ports.auth.current(), this.ports.records.load()])

      return { actor, state }
    })
  }

  signIn(role: Role, email: string, password: string): Promise<AuthOutcome> {
    return this.step(() => this.ports.auth.signIn(role, email, password))
  }

  enterStaff(pin: string, name: string): Promise<StaffOutcome> {
    return this.step(async () => {
      const state = await this.ports.records.load()

      return this.ports.auth.enterStaff(pin, state.access, name)
    })
  }

  signOut() {
    return this.step(() => this.ports.auth.signOut())
  }

  previewAs(role: Role) {
    return this.step(() => this.ports.auth.previewAs(role))
  }

  setAccess(access: AccessState) {
    return this.step(async () => {
      const held = await this.hold(Gate.Owner)

      if (!held) {
        return null
      }

      return this.ports.records.commit({ kind: "access.set", access })
    })
  }

  addEntry(input: NewEntry) {
    return this.step(async () => {
      const held = await this.hold(Gate.Any)
      const body = composeBody(input)

      if (!held || !body) {
        return null
      }

      const fileIds = await this.storeEntryFiles(input)
      const stamped = stampNow(held.state.tick)
      const entry: DiaryEntry = {
        id: makeId("entry"),
        kind: input.kind,
        body,
        authorName: held.actor.name,
        authorRole: held.actor.role,
        when: stamped.when,
        attachment: input.attachment,
        voice: input.voice,
        question: input.kind === EntryKind.Question ? QuestionState.Open : null,
        fileIds,
      }
      const saved = await this.ports.records.commit({ kind: "entry.add", entry })
      const handover = await this.ports.model.summariseDiary(saved.entries)

      return this.ports.records.commit({ kind: "handover.set", text: handover })
    })
  }

  resolveQuestion(id: string) {
    return this.step(async () => {
      const held = await this.hold(Gate.Owner)

      if (!held) {
        return null
      }

      return this.ports.records.commit({ kind: "question.resolve", id })
    })
  }

  saveAnswer(id: string, text: string) {
    return this.step(async () => {
      const held = await this.hold(Gate.Household)

      if (!held) {
        return null
      }

      return this.ports.records.commit({ kind: "answer.save", id, text: text.trim() })
    })
  }

  addObservation(worksId: string, text: string) {
    return this.step(async () => {
      const held = await this.hold(Gate.Any)
      const line = text.trim()

      if (!held || !line) {
        return null
      }

      return this.ports.records.commit({
        kind: "observation.add",
        worksId,
        line: `${held.actor.name}: ${line}`,
      })
    })
  }

  sendChat(text: string) {
    return this.step(async () => {
      const held = await this.hold(Gate.Any)
      const trimmed = text.trim()

      if (!held || !trimmed) {
        return null
      }

      const answer = await this.ports.model.answerCare(trimmed, held.state.entries)
      const first = stampNow(held.state.tick)
      const second = stampNow(first.tick)
      const notes: Note[] = [
        this.personNote(Thread.Care, held.actor.name, trimmed, first.when),
        {
          id: makeId("note"),
          thread: Thread.Care,
          source: MessageSource.Ai,
          author: "Pocket",
          body: answer.body,
          when: second.when,
          known: answer.known,
          escalation: answer.known === Known.No ? Escalation.None : null,
          asked: trimmed,
        },
      ]

      return this.ports.records.commit({ kind: "messages.add", notes })
    })
  }

  sendToOwner(id: string) {
    return this.step(async () => {
      const held = await this.hold(Gate.Household)

      if (!held) {
        return null
      }

      const note = held.state.messages.find((item) => item.id === id)

      if (!note?.asked || note.escalation === Escalation.Sent) {
        return held.state
      }

      const stamped = stampNow(held.state.tick)
      const message = this.personNote(Thread.Care, held.actor.name, `Asked Alex: ${note.asked}`, stamped.when)

      return this.ports.records.commit({ kind: "message.sent", id, note: message })
    })
  }

  sendGuide(text: string) {
    return this.step(async () => {
      const held = await this.hold(Gate.Household)
      const trimmed = text.trim()

      if (!held || !trimmed) {
        return null
      }

      const spoken = held.state.messages.filter((item) => {
        return item.thread === Thread.Guide && item.source === MessageSource.Person
      }).length
      const reply = await this.ports.model.guideReply(spoken)
      const first = stampNow(held.state.tick)
      const second = stampNow(first.tick)

      // Guide notes are a separate thread. applyCommand never copies them into diary entries.
      return this.ports.records.commit({
        kind: "messages.add",
        notes: [
          this.personNote(Thread.Guide, held.actor.name, trimmed, first.when),
          {
            id: makeId("note"),
            thread: Thread.Guide,
            source: MessageSource.Ai,
            author: "Pocket",
            body: reply,
            when: second.when,
            known: null,
            escalation: null,
            asked: null,
          },
        ],
      })
    })
  }

  acceptHelp(id: string) {
    return this.step(async () => {
      const held = await this.hold(Gate.Household)

      if (!held) {
        return null
      }

      return this.ports.records.commit({ kind: "help.accept", id, name: held.actor.name })
    })
  }

  postRequest(kind: RequestKind) {
    return this.step(async () => {
      const held = await this.hold(Gate.Owner)

      if (!held) {
        return null
      }

      const open = held.state.requests.some((item) => item.kind === kind && !item.acceptedBy)

      if (open) {
        return held.state
      }

      return this.ports.records.commit({
        kind: "help.post",
        request: {
          id: makeId("help"),
          kind,
          text: requestText(kind),
          acceptedBy: null,
        },
      })
    })
  }

  toggleReminder(id: string) {
    return this.step(async () => {
      const held = await this.hold(Gate.Household)

      if (!held) {
        return null
      }

      const item = held.state.appointments.find((appointment) => appointment.id === id)

      if (!item) {
        return held.state
      }

      const reminder = item.reminder === Reminder.On ? Reminder.Off : Reminder.On

      return this.ports.records.commit({ kind: "reminder.set", id, reminder })
    })
  }

  volunteer(id: string) {
    return this.step(async () => {
      const held = await this.hold(Gate.Household)

      if (!held) {
        return null
      }

      return this.ports.records.commit({ kind: "volunteer.set", id, name: held.actor.name })
    })
  }

  addReport(input: NewReport) {
    return this.step(async () => {
      const held = await this.hold(Gate.Owner)
      const title = input.title.trim()
      const original = input.original.trim()

      if (!held || !title || !original) {
        return null
      }

      const file = await this.ports.files.put(FileKind.Document, title)
      const summary = await this.ports.model.summariseReport(original)
      const stamped = stampNow(held.state.tick)

      return this.ports.records.commit({
        kind: "report.add",
        report: {
          id: makeId("report"),
          when: stamped.when,
          author: input.author.trim() || "Not named",
          title,
          note: input.note.trim(),
          original,
          summary,
          fileId: file.id,
        },
      })
    })
  }

  private async hold(gate: Gate): Promise<Held | null> {
    const [actor, state] = await Promise.all([this.ports.auth.current(), this.ports.records.load()])

    if (!actor || !passes(actor, gate)) {
      return null
    }

    return { actor, state }
  }

  private async storeEntryFiles(input: NewEntry): Promise<string[]> {
    const ids: string[] = []

    if (input.attachment === Attachment.Photo) {
      const file = await this.ports.files.put(FileKind.Photo, "Photo")
      ids.push(file.id)
    }

    if (input.voice === VoiceNote.Sample) {
      const file = await this.ports.files.put(FileKind.Voice, "Voice note")
      ids.push(file.id)
    }

    return ids
  }

  private personNote(thread: Thread, author: string, body: string, when: Note["when"]): Note {
    return {
      id: makeId("note"),
      thread,
      source: MessageSource.Person,
      author,
      body,
      when,
      known: null,
      escalation: null,
      asked: null,
    }
  }

  // One use case at a time, so two taps cannot overwrite each other's record.
  private step<T>(work: () => Promise<T>): Promise<T> {
    const run = this.tail.then(work, work)

    this.tail = run.then(
      () => undefined,
      () => undefined,
    )

    return run
  }
}
