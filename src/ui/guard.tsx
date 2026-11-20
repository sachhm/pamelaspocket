import { ReactNode } from "react"
import { Redirect } from "expo-router"

import { Role } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"

export function Guard({ roles, children }: { roles: Role[]; children: ReactNode }) {
  const { actor } = usePocket()

  if (!actor) {
    return <Redirect href="/" />
  }

  if (!roles.includes(actor.role)) {
    return <Redirect href="/today" />
  }

  return <>{children}</>
}
