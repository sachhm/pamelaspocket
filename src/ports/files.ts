export enum FileKind {
  Photo = "photo",
  Voice = "voice",
  Document = "document",
}

export type StoredFile = {
  id: string
  kind: FileKind
  label: string
}

// Bytes stay behind this port. The local adapter stores a reference only.
export interface FilePort {
  put(kind: FileKind, label: string): Promise<StoredFile>
}
