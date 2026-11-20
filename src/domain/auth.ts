import { Actor, PinResult, Role, SignInResult, AccessState } from "@/src/domain/types"

export const OWNER_EMAIL = "alex@pocket.demo"
export const FAMILY_EMAIL = "chris@pocket.demo"
export const DEMO_PASSWORD = "pocket"
export const DEMO_PIN = "2580"
export const PIN_LENGTH = 4

export const STAFF_NAMES = ["Jordan", "Sam"] as const

export function emailFor(role: Role): string {
  if (role === Role.Family) {
    return FAMILY_EMAIL
  }

  return OWNER_EMAIL
}

export function actorFor(role: Role): Actor {
  if (role === Role.Owner) {
    return { role, name: "Alex" }
  }

  if (role === Role.Family) {
    return { role, name: "Chris" }
  }

  return { role, name: "Jordan" }
}

export function checkSignIn(role: Role, email: string, password: string): SignInResult {
  if (role === Role.Staff) {
    return SignInResult.Rejected
  }

  const emailOk = email.trim().toLowerCase() === emailFor(role)
  const passwordOk = password === DEMO_PASSWORD

  if (emailOk && passwordOk) {
    return SignInResult.Ok
  }

  return SignInResult.Rejected
}

export function checkPin(pin: string, access: AccessState): PinResult {
  if (access === AccessState.Revoked) {
    return PinResult.Revoked
  }

  if (pin === DEMO_PIN) {
    return PinResult.Ok
  }

  return PinResult.Wrong
}
