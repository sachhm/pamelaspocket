// One error shape for every remote adapter. status 0 means the network never answered.
export class ApiError extends Error {
  readonly status: number

  constructor(status: number, message: string) {
    super(message)
    this.status = status
  }
}
