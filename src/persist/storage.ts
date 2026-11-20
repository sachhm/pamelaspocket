import AsyncStorage from "@react-native-async-storage/async-storage"

import { createSeed } from "@/src/domain/seed"
import { Actor, DiaryEntry, PocketState, Report, SavedPack } from "@/src/domain/types"

const LEGACY_KEY = "pamelas-pocket.v1"
const STATE_KEY = "pamelas-pocket.records.v2"
const ACTOR_KEY = "pamelas-pocket.actor.v2"

function isState(value: unknown): value is PocketState {
  if (!value || typeof value !== "object") {
    return false
  }

  const state = value as PocketState

  return Array.isArray(state.entries) && Array.isArray(state.messages)
}

function isActor(value: unknown): value is Actor {
  if (!value || typeof value !== "object") {
    return false
  }

  const actor = value as Actor

  return typeof actor.name === "string" && typeof actor.role === "string"
}

function withFiles(entry: DiaryEntry): DiaryEntry {
  return { ...entry, fileIds: entry.fileIds ?? [] }
}

function withReportFile(report: Report): Report {
  return { ...report, fileId: report.fileId ?? null }
}

// Older saves predate file references. Fill them so the rest of the app can assume the fields.
export function normalizeState(state: PocketState): PocketState {
  return {
    ...state,
    entries: state.entries.map(withFiles),
    reports: state.reports.map(withReportFile),
  }
}

async function readJson(key: string): Promise<unknown> {
  const raw = await AsyncStorage.getItem(key)

  if (!raw) {
    return null
  }

  return JSON.parse(raw) as unknown
}

async function migrateLegacy(): Promise<void> {
  const current = await AsyncStorage.getItem(STATE_KEY)

  if (current) {
    return
  }

  const legacy = await readJson(LEGACY_KEY)

  if (!legacy || typeof legacy !== "object") {
    return
  }

  const pack = legacy as SavedPack

  if (!isState(pack.state)) {
    return
  }

  await AsyncStorage.setItem(STATE_KEY, JSON.stringify(normalizeState(pack.state)))
  await AsyncStorage.setItem(ACTOR_KEY, JSON.stringify(pack.actor ?? null))
  await AsyncStorage.removeItem(LEGACY_KEY)
}

export async function loadState(): Promise<PocketState | null> {
  try {
    await migrateLegacy()
    const parsed = await readJson(STATE_KEY)

    if (!isState(parsed)) {
      return null
    }

    return normalizeState(parsed)
  } catch {
    return null
  }
}

export async function saveState(state: PocketState): Promise<void> {
  try {
    await AsyncStorage.setItem(STATE_KEY, JSON.stringify(state))
  } catch {
    return
  }
}

export async function loadActor(): Promise<Actor | null> {
  try {
    await migrateLegacy()
    const parsed = await readJson(ACTOR_KEY)

    if (!isActor(parsed)) {
      return null
    }

    return parsed
  } catch {
    return null
  }
}

export async function saveActor(actor: Actor | null): Promise<void> {
  try {
    await AsyncStorage.setItem(ACTOR_KEY, JSON.stringify(actor))
  } catch {
    return
  }
}

export function freshState(): PocketState {
  return createSeed()
}
