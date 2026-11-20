import { AuthPort } from "@/src/ports/auth"
import { FilePort } from "@/src/ports/files"
import { ModelPort } from "@/src/ports/model"
import { RecordPort } from "@/src/ports/records"

export type CarePorts = {
  auth: AuthPort
  records: RecordPort
  model: ModelPort
  files: FilePort
}
