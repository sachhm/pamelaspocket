import { actorFor, checkPin, checkSignIn } from "@/src/domain/auth"
import { AccessState, PinResult, Role, SignInResult } from "@/src/domain/types"
import { loadActor, saveActor } from "@/src/persist/storage"
import { AuthOutcome, AuthPort, StaffOutcome } from "@/src/ports/auth"

export class LocalAuth implements AuthPort {
  async current() {
    return loadActor()
  }

  async signIn(role: Role, email: string, password: string): Promise<AuthOutcome> {
    const result = checkSignIn(role, email, password)

    if (result !== SignInResult.Ok) {
      return { result, actor: null }
    }

    const actor = actorFor(role)
    await saveActor(actor)

    return { result, actor }
  }

  async enterStaff(pin: string, access: AccessState, name: string): Promise<StaffOutcome> {
    const result = checkPin(pin, access)

    if (result !== PinResult.Ok) {
      return { result, actor: null }
    }

    const actor = { role: Role.Staff, name }
    await saveActor(actor)

    return { result, actor }
  }

  async signOut() {
    await saveActor(null)
  }

  async previewAs(role: Role) {
    const actor = actorFor(role)
    await saveActor(actor)

    return actor
  }
}
