export const AuthError = {
  INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  INVALID_TOKEN: 'INVALID_TOKEN',
} as const;

export type AuthError = (typeof AuthError)[keyof typeof AuthError];
