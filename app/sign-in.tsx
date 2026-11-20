import { useState } from "react"
import { Redirect, useLocalSearchParams } from "expo-router"

import { DEMO_PASSWORD, emailFor } from "@/src/domain/auth"
import { ButtonTone, FieldPrivacy, FieldSize, Role, SignInResult } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Body, Button, Field, Meta, Title } from "@/src/ui/bits"
import { Screen } from "@/src/ui/screen"

export default function SignIn() {
  const { actor, signIn } = usePocket()
  const params = useLocalSearchParams<{ role?: string }>()
  const raw = Array.isArray(params.role) ? params.role[0] : params.role
  const role = raw === Role.Family ? Role.Family : Role.Owner
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [error, setError] = useState("")

  if (actor) {
    return <Redirect href="/today" />
  }

  async function onSubmit() {
    try {
      const result = await signIn(role, email, password)

      if (result === SignInResult.Rejected) {
        setError("That email or password was not accepted.")
      }
    } catch {
      setError("The sign-in service did not answer.")
    }
  }

  const who = role === Role.Family ? "Family member" : "Primary carer"

  return (
    <Screen title="Sign in">
      <Title>{who}</Title>
      <Body>Use the demo account. There is no new registration in this preview.</Body>
      <Field
        label="Email"
        value={email}
        onChange={(value) => {
          setEmail(value)
          setError("")
        }}
        privacy={FieldPrivacy.Public}
        size={FieldSize.Line}
        hint={emailFor(role)}
      />
      <Field
        label="Password"
        value={password}
        onChange={(value) => {
          setPassword(value)
          setError("")
        }}
        privacy={FieldPrivacy.Secret}
        size={FieldSize.Line}
        hint="password"
      />
      {error ? <Body>{error}</Body> : null}
      <Button
        label="Use the demo account"
        tone={ButtonTone.Primary}
        onPress={() => {
          void signIn(role, emailFor(role), DEMO_PASSWORD)
        }}
      />
      <Button label="Continue" tone={ButtonTone.Quiet} onPress={onSubmit} />
      <Meta>
        Demo {emailFor(role)} / {DEMO_PASSWORD}
      </Meta>
    </Screen>
  )
}
