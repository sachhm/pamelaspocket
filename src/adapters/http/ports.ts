import { getJson, postJson } from "@/src/adapters/http/client"
import { AccessState, Actor, Answer, DiaryEntry, PocketState, Role } from "@/src/domain/types"
import { AuthOutcome, AuthPort, StaffOutcome } from "@/src/ports/auth"
import { FileKind, FilePort, StoredFile } from "@/src/ports/files"
import { ModelPort } from "@/src/ports/model"
import { CareCommand, RecordPort } from "@/src/ports/records"

// POST /v1/auth/sign-in { role, email, password } -> { result, actor }
// POST /v1/auth/staff { pin, name, access } -> { result, actor }
// POST /v1/auth/sign-out
// GET  /v1/auth/session -> { actor }
// POST /v1/auth/preview { role } -> { actor }
export class HttpAuth implements AuthPort {
  constructor(private readonly root: string) {}

  async current() {
    const body = await getJson<{ actor: Actor | null }>(`${this.root}/v1/auth/session`)

    return body.actor
  }

  async signIn(role: Role, email: string, password: string) {
    return postJson<AuthOutcome>(`${this.root}/v1/auth/sign-in`, { role, email, password })
  }

  async enterStaff(pin: string, access: AccessState, name: string) {
    return postJson<StaffOutcome>(`${this.root}/v1/auth/staff`, { pin, name, access })
  }

  async signOut() {
    await postJson<unknown>(`${this.root}/v1/auth/sign-out`, {})
  }

  async previewAs(role: Role) {
    const body = await postJson<{ actor: Actor }>(`${this.root}/v1/auth/preview`, { role })

    return body.actor
  }
}

// GET  /v1/records -> PocketState
// POST /v1/records/commands { command } -> PocketState
export class HttpRecords implements RecordPort {
  constructor(private readonly root: string) {}

  load() {
    return getJson<PocketState>(`${this.root}/v1/records`)
  }

  commit(command: CareCommand) {
    return postJson<PocketState>(`${this.root}/v1/records/commands`, { command })
  }
}

// POST /v1/model/care { text, entries } -> Answer
// POST /v1/model/guide { spoken } -> { text }
// POST /v1/model/handover { entries } -> { text }
// POST /v1/model/report { original } -> { text }
export class HttpModel implements ModelPort {
  constructor(private readonly root: string) {}

  answerCare(text: string, entries: DiaryEntry[]) {
    return postJson<Answer>(`${this.root}/v1/model/care`, { text, entries })
  }

  async guideReply(spokenCount: number) {
    const body = await postJson<{ text: string }>(`${this.root}/v1/model/guide`, { spoken: spokenCount })

    return body.text
  }

  async summariseDiary(entries: DiaryEntry[]) {
    const body = await postJson<{ text: string }>(`${this.root}/v1/model/handover`, { entries })

    return body.text
  }

  async summariseReport(original: string) {
    const body = await postJson<{ text: string }>(`${this.root}/v1/model/report`, { original })

    return body.text
  }
}

// POST /v1/files { kind, label } -> { id, kind, label }
export class HttpFiles implements FilePort {
  constructor(private readonly root: string) {}

  put(kind: FileKind, label: string) {
    return postJson<StoredFile>(`${this.root}/v1/files`, { kind, label })
  }
}
