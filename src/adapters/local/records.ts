import { applyCommand } from "@/src/domain/apply"
import { PocketState } from "@/src/domain/types"
import { freshState, loadState, saveState } from "@/src/persist/storage"
import { CareCommand, RecordPort } from "@/src/ports/records"

// Keeps the household in memory and on device. commit is the only write.
export class LocalRecords implements RecordPort {
  private state: PocketState | null = null

  async load() {
    if (this.state) {
      return this.state
    }

    const saved = await loadState()
    this.state = saved ?? freshState()

    if (!saved) {
      await saveState(this.state)
    }

    return this.state
  }

  async commit(command: CareCommand) {
    const current = await this.load()
    const next = applyCommand(current, command)
    this.state = next
    await saveState(next)

    return next
  }
}
