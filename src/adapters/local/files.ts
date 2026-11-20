import { makeId } from "@/src/domain/time"
import { FileKind, FilePort, StoredFile } from "@/src/ports/files"

export class LocalFiles implements FilePort {
  async put(kind: FileKind, label: string): Promise<StoredFile> {
    return { id: makeId("file"), kind, label }
  }
}
