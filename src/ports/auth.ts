import { AccessState, Actor, PinResult, Role, SignInResult } from "@/src/domain/types"

export type AuthOutcome = {
  result: SignInResult
  actor: Actor | null
}

export type StaffOutcome = {
  result: PinResult
  actor: Actor | null
}

// Account and staff-gate calls. A remote adapter replaces this without touching screens.
export interface AuthPort {
  current(): Promise<Actor | null>
  signIn(role: Role, email: string, password: string): Promise<AuthOutcome>
  enterStaff(pin: string, access: AccessState, name: string): Promise<StaffOutcome>
  signOut(): Promise<void>
  previewAs(role: Role): Promise<Actor>
}
