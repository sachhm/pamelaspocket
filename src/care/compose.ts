import { LocalAuth } from "@/src/adapters/local/auth"
import { LocalFiles } from "@/src/adapters/local/files"
import { LocalModel } from "@/src/adapters/local/model"
import { LocalRecords } from "@/src/adapters/local/records"
import { HttpAuth, HttpFiles, HttpModel, HttpRecords } from "@/src/adapters/http/ports"
import { CareDesk } from "@/src/care/desk"
import { CarePorts } from "@/src/ports/bundle"

// Set EXPO_PUBLIC_API_URL to send auth, records, model, and files to that origin.
// Leave it empty to keep the on-device adapters.
function apiRoot(): string {
  const value = process.env.EXPO_PUBLIC_API_URL ?? ""

  return value.replace(/\/$/, "")
}

export function usesRemoteApi(): boolean {
  return apiRoot().length > 0
}

export function createDesk(): CareDesk {
  return new CareDesk(ports())
}

function ports(): CarePorts {
  const root = apiRoot()

  if (!root) {
    return {
      auth: new LocalAuth(),
      records: new LocalRecords(),
      model: new LocalModel(),
      files: new LocalFiles(),
    }
  }

  return {
    auth: new HttpAuth(root),
    records: new HttpRecords(root),
    model: new HttpModel(root),
    files: new HttpFiles(root),
  }
}
