import {
  AccessState,
  DiaryEntry,
  HelpRequest,
  Note,
  PocketState,
  Reminder,
  Report,
} from "@/src/domain/types"

// One command, one future HTTP call. The desk builds these after permission checks.
export type CareCommand =
  | { kind: "entry.add"; entry: DiaryEntry }
  | { kind: "question.resolve"; id: string }
  | { kind: "answer.save"; id: string; text: string }
  | { kind: "observation.add"; worksId: string; line: string }
  | { kind: "messages.add"; notes: Note[] }
  | { kind: "message.sent"; id: string; note: Note }
  | { kind: "help.accept"; id: string; name: string }
  | { kind: "help.post"; request: HelpRequest }
  | { kind: "reminder.set"; id: string; reminder: Reminder }
  | { kind: "volunteer.set"; id: string; name: string }
  | { kind: "handover.set"; text: string }
  | { kind: "access.set"; access: AccessState }
  | { kind: "report.add"; report: Report }

export interface RecordPort {
  load(): Promise<PocketState>
  commit(command: CareCommand): Promise<PocketState>
}
