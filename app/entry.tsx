import { useState } from "react"
import { View, StyleSheet } from "react-native"
import { router } from "expo-router"

import { SAMPLE_VOICE, composeBody } from "@/src/domain/copy"
import { Attachment, ButtonTone, EntryKind, FieldPrivacy, FieldSize, VoiceNote } from "@/src/domain/types"
import { usePocket } from "@/src/session/pocket"
import { Body, Button, Chip, Field, Meta } from "@/src/ui/bits"
import { entryLabel } from "@/src/ui/labels"
import { Screen } from "@/src/ui/screen"
import { Space } from "@/src/theme"

const KINDS = [
  EntryKind.General,
  EntryKind.Mood,
  EntryKind.Important,
  EntryKind.Question,
  EntryKind.Moment,
]

export default function Entry() {
  const { addEntry } = usePocket()
  const [kind, setKind] = useState(EntryKind.General)
  const [draft, setDraft] = useState("")
  const [attachment, setAttachment] = useState(Attachment.None)
  const [voice, setVoice] = useState(VoiceNote.None)

  const preview = composeBody({ body: draft, voice, attachment })

  function onPhoto() {
    setAttachment((current) => (current === Attachment.Photo ? Attachment.None : Attachment.Photo))
  }

  function onVoice() {
    setVoice((current) => (current === VoiceNote.Sample ? VoiceNote.None : VoiceNote.Sample))
  }

  function onSave() {
    if (!preview) {
      return
    }

    addEntry({ kind, body: draft, attachment, voice })
    router.back()
  }

  return (
    <Screen
      title="New update"
      footer={<Button label="Save update" tone={ButtonTone.Primary} onPress={onSave} disabled={!preview} />}
    >
      <View style={styles.kinds}>
        {KINDS.map((item) => (
          <Chip key={item} label={entryLabel(item)} selected={kind === item} onPress={() => setKind(item)} />
        ))}
      </View>
      <Field
        label="Note"
        value={draft}
        onChange={setDraft}
        privacy={FieldPrivacy.Public}
        size={FieldSize.Story}
        hint="What should the next person know?"
      />
      <View style={styles.kinds}>
        <Chip label={attachment === Attachment.Photo ? "Photo added" : "Add photo"} selected={attachment === Attachment.Photo} onPress={onPhoto} />
        <Chip label={voice === VoiceNote.Sample ? "Voice added" : "Voice note"} selected={voice === VoiceNote.Sample} onPress={onVoice} />
      </View>
      {voice === VoiceNote.Sample ? <Meta>{SAMPLE_VOICE}</Meta> : null}
      {!preview ? <Body>Write a note, or add a photo or voice line.</Body> : null}
    </Screen>
  )
}

const styles = StyleSheet.create({
  kinds: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Space.sm,
  },
})
