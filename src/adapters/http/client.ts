import { ApiError } from "@/src/ports/error"

const HEADERS = {
  accept: "application/json",
  "content-type": "application/json",
}

// Shared fetch for the HTTP adapters. Paths are the contract a backend implements.
export async function postJson<T>(url: string, body: unknown): Promise<T> {
  return sendJson<T>(url, "POST", body)
}

export async function getJson<T>(url: string): Promise<T> {
  return sendJson<T>(url, "GET", null)
}

async function sendJson<T>(url: string, method: "GET" | "POST", body: unknown): Promise<T> {
  let response: Response

  try {
    response = await fetch(url, {
      method,
      headers: HEADERS,
      body: body === null ? undefined : JSON.stringify(body),
    })
  } catch {
    throw new ApiError(0, "The care service could not be reached.")
  }

  if (!response.ok) {
    throw new ApiError(response.status, "The care service rejected the request.")
  }

  return (await response.json()) as T
}
