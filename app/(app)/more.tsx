import { View, StyleSheet } from "react-native"
import { Href, router } from "expo-router"

import { compareWhen, formatWhen } from "@/src/domain/time"
import { ButtonTone, CardTone, Role } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Body, Button, Card, Chip, Meta, Title } from "@/src/ui/bits"
import { roleLabel } from "@/src/ui/labels"
import { Screen } from "@/src/ui/screen"
import { Space } from "@/src/theme"

const ROLES = [Role.Owner, Role.Staff, Role.Family]

export default function More() {
  const { actor, state, switchRole, signOut, remote } = usePocket()

  if (!actor) {
    return null
  }

  const reports = [...state.reports].sort((a, b) => compareWhen(b.when, a.when))
  const showReports = actor.role !== Role.Staff

  return (
    <Screen>
      <Title>More</Title>
      <Card tone={CardTone.Soft}>
        <Meta>Signed in as</Meta>
        <Body>
          {actor.name}, {roleLabel(actor.role)}
        </Body>
      </Card>

      <Meta>Preview as</Meta>
      <View style={styles.row}>
        {ROLES.map((role) => (
          <Chip
            key={role}
            label={roleLabel(role)}
            selected={actor.role === role}
            onPress={() => switchRole(role)}
          />
        ))}
      </View>

      {actor.role === Role.Owner ? (
        <Button
          label="People, QR and PIN"
          tone={ButtonTone.Primary}
          onPress={() => router.push("/access")}
        />
      ) : null}

      {actor.role === Role.Staff ? (
        <Body>Family plans, the private guide, reports, and access codes are hidden for staff.</Body>
      ) : null}

      {remote ? null : (
        <Meta>Care data stays on this device until an API URL is connected.</Meta>
      )}

      {showReports ? (
        <View style={styles.block}>
          <Meta>Reports</Meta>
          {actor.role === Role.Owner ? (
            <Button label="Add a report" tone={ButtonTone.Quiet} onPress={() => router.push("/report/new")} />
          ) : null}
          {reports.map((report) => (
            <Card key={report.id} tone={CardTone.Soft}>
              <Body>{report.title}</Body>
              <Meta>
                {report.author} · {formatWhen(report.when)}
              </Meta>
              <Meta>{report.note}</Meta>
              <Button
                label="Open"
                tone={ButtonTone.Quiet}
                onPress={() => router.push(`/report/${report.id}` as Href)}
              />
            </Card>
          ))}
        </View>
      ) : null}

      <Button label="Sign out" tone={ButtonTone.Quiet} onPress={signOut} />
    </Screen>
  )
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Space.sm,
  },
  block: {
    gap: Space.sm,
  },
})
