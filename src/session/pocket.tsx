import { createContext, ReactNode, useContext, useEffect, useState } from "react"
import { Text, View } from "react-native"

import { createDesk, usesRemoteApi } from "@/src/care/compose"
import { CareDesk } from "@/src/care/desk"
import {
  AccessState,
  Actor,
  NewEntry,
  NewReport,
  PinResult,
  PocketState,
  RequestKind,
  Role,
  SignInResult,
} from "@/src/domain/types"
import { ApiError } from "@/src/ports/error"
import { Color, Font, Space } from "@/src/theme"

type PocketApi = {
  actor: Actor | null
  state: PocketState
  remote: boolean
  fault: string
  signIn: (role: Role, email: string, password: string) => Promise<SignInResult>
  enterStaff: (pin: string, name: string) => Promise<PinResult>
  signOut: () => void
  switchRole: (role: Role) => void
  revokeAccess: () => void
  restoreAccess: () => void
  addEntry: (input: NewEntry) => void
  resolveQuestion: (id: string) => void
  saveAnswer: (id: string, text: string) => void
  addObservation: (worksId: string, text: string) => void
  sendChat: (text: string) => void
  sendToOwner: (id: string) => void
  sendGuide: (text: string) => void
  acceptHelp: (id: string) => void
  postRequest: (kind: RequestKind) => void
  toggleReminder: (id: string) => void
  volunteer: (id: string) => void
  addReport: (input: NewReport) => Promise<boolean>
}

const PocketContext = createContext<PocketApi | null>(null)

export function usePocket(): PocketApi {
  const api = useContext(PocketContext)

  if (!api) {
    throw new Error("usePocket must sit inside PocketProvider")
  }

  return api
}

type Held = {
  actor: Actor | null
  state: PocketState
}

function faultText(error: unknown): string {
  if (error instanceof ApiError) {
    return error.message
  }

  return "The care service did not answer."
}

// React binding only. Rules live on CareDesk, which is the layer under this one.
export function PocketProvider({ children }: { children: ReactNode }) {
  const [desk] = useState(() => createDesk())
  const [held, setHeld] = useState<Held | null>(null)
  const [fault, setFault] = useState("")

  useEffect(() => {
    let live = true

    desk.load().then((pack) => {
      if (!live) {
        return
      }

      setHeld(pack)
    }).catch((error: unknown) => {
      if (!live) {
        return
      }

      setFault(faultText(error))
    })

    return () => {
      live = false
    }
  }, [desk])

  function remember(next: PocketState | null) {
    if (!next) {
      return
    }

    setFault("")
    setHeld((current) => {
      if (!current) {
        return current
      }

      return { ...current, state: next }
    })
  }

  function run(work: (service: CareDesk) => Promise<PocketState | null>) {
    work(desk).then(remember).catch((error: unknown) => {
      setFault(faultText(error))
    })
  }

  const signIn = async (role: Role, email: string, password: string) => {
    const outcome = await desk.signIn(role, email, password)

    if (outcome.actor) {
      setFault("")
      setHeld((current) => (current ? { ...current, actor: outcome.actor } : current))
    }

    return outcome.result
  }

  const enterStaff = async (pin: string, name: string) => {
    const outcome = await desk.enterStaff(pin, name)

    if (outcome.actor) {
      setFault("")
      setHeld((current) => (current ? { ...current, actor: outcome.actor } : current))
    }

    return outcome.result
  }

  const signOut = () => {
    desk.signOut().then(() => {
      setHeld((current) => (current ? { ...current, actor: null } : current))
    }).catch((error: unknown) => {
      setFault(faultText(error))
    })
  }

  const switchRole = (role: Role) => {
    desk.previewAs(role).then((actor) => {
      setHeld((current) => (current ? { ...current, actor } : current))
    }).catch((error: unknown) => {
      setFault(faultText(error))
    })
  }

  const addReport = async (input: NewReport) => {
    const next = await desk.addReport(input)
    remember(next)

    return next !== null
  }

  if (!held && fault) {
    return <FaultBanner fault={fault} />
  }

  if (!held) {
    return null
  }

  const api: PocketApi = {
    actor: held.actor,
    state: held.state,
    remote: usesRemoteApi(),
    fault,
    signIn,
    enterStaff,
    signOut,
    switchRole,
    revokeAccess: () => run((service) => service.setAccess(AccessState.Revoked)),
    restoreAccess: () => run((service) => service.setAccess(AccessState.Active)),
    addEntry: (input) => run((service) => service.addEntry(input)),
    resolveQuestion: (id) => run((service) => service.resolveQuestion(id)),
    saveAnswer: (id, text) => run((service) => service.saveAnswer(id, text)),
    addObservation: (id, text) => run((service) => service.addObservation(id, text)),
    sendChat: (text) => run((service) => service.sendChat(text)),
    sendToOwner: (id) => run((service) => service.sendToOwner(id)),
    sendGuide: (text) => run((service) => service.sendGuide(text)),
    acceptHelp: (id) => run((service) => service.acceptHelp(id)),
    postRequest: (kind) => run((service) => service.postRequest(kind)),
    toggleReminder: (id) => run((service) => service.toggleReminder(id)),
    volunteer: (id) => run((service) => service.volunteer(id)),
    addReport,
  }

  return (
    <PocketContext.Provider value={api}>
      {fault ? <FaultBanner fault={fault} /> : null}
      {children}
    </PocketContext.Provider>
  )
}

function FaultBanner({ fault }: { fault: string }) {
  return (
    <View style={{ backgroundColor: Color.bronze, padding: Space.md }}>
      <Text style={{ color: Color.brown, fontFamily: Font.body, fontSize: 16 }}>{fault}</Text>
    </View>
  )
}
