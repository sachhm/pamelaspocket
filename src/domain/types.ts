export enum Role {
  Owner = "owner",
  Staff = "staff",
  Family = "family",
}

export enum EntryKind {
  General = "general",
  Mood = "mood",
  Important = "important",
  Question = "question",
  Moment = "moment",
}

export enum QuestionState {
  Open = "open",
  Resolved = "resolved",
}

export enum Attachment {
  None = "none",
  Photo = "photo",
}

export enum VoiceNote {
  None = "none",
  Sample = "sample",
}

export enum MessageSource {
  Person = "person",
  Ai = "ai",
}

export enum Thread {
  Care = "care",
  Guide = "guide",
}

export enum Known {
  Yes = "yes",
  No = "no",
}

export enum Escalation {
  None = "none",
  Sent = "sent",
}

export enum AccessState {
  Active = "active",
  Revoked = "revoked",
}

export enum RequestKind {
  Appointment = "appointment",
  Visit = "visit",
  Prescription = "prescription",
}

export enum Reminder {
  Off = "off",
  On = "on",
}

export enum StorySection {
  Life = "life",
  Personality = "personality",
  Routines = "routines",
}

export enum AboutTab {
  Life = "life",
  Personality = "personality",
  Routines = "routines",
  Works = "works",
}

export enum SignInResult {
  Ok = "ok",
  Rejected = "rejected",
}

export enum PinResult {
  Ok = "ok",
  Wrong = "wrong",
  Revoked = "revoked",
}

export enum ButtonTone {
  Primary = "primary",
  Quiet = "quiet",
}

export enum CardTone {
  Soft = "soft",
  Note = "note",
  Ai = "ai",
}

export enum FieldPrivacy {
  Public = "public",
  Secret = "secret",
}

export enum FieldSize {
  Line = "line",
  Story = "story",
}

export enum AiKind {
  Summary = "summary",
  Reply = "reply",
}

// Day offset keeps seeded "today" on the day the demo is opened.
export type When = {
  dayOffset: number
  hour: number
  minute: number
  seq: number
}

export type Actor = {
  role: Role
  name: string
}

export type Person = {
  name: string
  role: Role
}

export type DiaryEntry = {
  id: string
  kind: EntryKind
  body: string
  authorName: string
  authorRole: Role
  when: When
  attachment: Attachment
  voice: VoiceNote
  question: QuestionState | null
  fileIds: string[]
}

export type NewReport = {
  title: string
  author: string
  note: string
  original: string
}

export type NewEntry = {
  kind: EntryKind
  body: string
  attachment: Attachment
  voice: VoiceNote
}

export type Prompt = {
  id: string
  section: StorySection
  ask: string
  answer: string
  year: string
}

export type WorkCard = {
  id: string
  situation: string
  helps: string
  hinders: string
  observations: string[]
  pattern: string
}

export type Note = {
  id: string
  thread: Thread
  source: MessageSource
  author: string
  body: string
  when: When
  known: Known | null
  escalation: Escalation | null
  asked: string | null
}

export type HelpRequest = {
  id: string
  kind: RequestKind
  text: string
  acceptedBy: string | null
}

export type Appointment = {
  id: string
  when: When
  place: string
  reason: string
  transport: string
  notes: string
  reminder: Reminder
  volunteer: string | null
}

export type Report = {
  id: string
  when: When
  author: string
  title: string
  note: string
  original: string
  summary: string
  fileId: string | null
}

export type PocketState = {
  tick: number
  access: AccessState
  handover: string
  nextVisit: string
  familyStatus: string
  people: Person[]
  entries: DiaryEntry[]
  prompts: Prompt[]
  works: WorkCard[]
  messages: Note[]
  requests: HelpRequest[]
  appointments: Appointment[]
  reports: Report[]
}

export type SavedPack = {
  actor: Actor | null
  state: PocketState
}

export type Answer = {
  known: Known
  body: string
}
