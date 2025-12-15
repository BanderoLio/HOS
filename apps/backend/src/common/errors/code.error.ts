export class CodeError<Code extends string> {
  constructor(
    public code: Code,
    public message?: string,
    public statusCode?: number,
  ) {}
}
