import { useLocalSearchParams } from "expo-router"

import { formatWhen } from "@/src/domain/time"
import { AiKind, CardTone, Role } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { AiMark, Body, Card, Meta } from "@/src/ui/bits"
import { Guard } from "@/src/ui/guard"
import { Screen } from "@/src/ui/screen"

export default function Report() {
  return (
    <Guard roles={[Role.Owner, Role.Family]}>
      <ReportPage />
    </Guard>
  )
}

function ReportPage() {
  const { state } = usePocket()
  const params = useLocalSearchParams<{ id: string }>()
  const raw = Array.isArray(params.id) ? params.id[0] : params.id
  const report = state.reports.find((item) => item.id === raw)

  if (!report) {
    return (
      <Screen title="Report">
        <Body>That report is not in the folder.</Body>
      </Screen>
    )
  }

  return (
    <Screen title={report.title}>
      <Meta>
        {report.author} · {formatWhen(report.when)}
      </Meta>
      <Body>{report.note}</Body>
      <Card tone={CardTone.Ai}>
        <AiMark kind={AiKind.Summary} />
        <Body>{report.summary}</Body>
      </Card>
      <Card tone={CardTone.Soft}>
        <Meta>Original</Meta>
        <Body>{report.original}</Body>
      </Card>
      <Meta>The original stays attached. This is not a clinical chart.</Meta>
    </Screen>
  )
}
