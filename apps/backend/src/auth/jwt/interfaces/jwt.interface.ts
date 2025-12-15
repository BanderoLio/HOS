export interface JwtPayload {
  sub?: string;
  exp?: number;
  type?: 'REFRESH' | 'ACCESS';
}
