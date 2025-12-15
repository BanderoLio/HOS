export class AuthResponseDto {
  accessToken: string;
  constructor(props: Partial<AuthResponseDto>) {
    Object.assign(this, props);
  }
}
