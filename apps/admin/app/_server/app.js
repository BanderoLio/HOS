import { createApp, createIdentityProvider } from '@kottster/server';
import schema from '../../kottster-app.json';

/* 
 * For security, consider moving the secret data to environment variables.
 * See https://kottster.app/docs/deploying#before-you-deploy
 */
export const app = createApp({
  schema,
  secretKey: 'TTruMjG_NngbinhD3jLvFPizuabmXQW6',
  kottsterApiToken: 't69CsEOFcr4KnsUJnfBJ4QuUmDIcNrQg',

  /*
   * The identity provider configuration.
   * See https://kottster.app/docs/app-configuration/identity-provider
   */
  identityProvider: createIdentityProvider('sqlite', {
    fileName: 'app.db',

    passwordHashAlgorithm: 'bcrypt',
    jwtSecretSalt: 'nzLa7yxtZFjDc8iN',
    
    /* The root admin user credentials */
    rootUsername: 'hos_admin',
    rootPassword: 'hos_admin',
  }),
});