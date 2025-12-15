import { KnexPgAdapter } from '@kottster/server';
import knex from 'knex';

/**
 * Learn more at https://knexjs.org/guide/#configuration-options
 */
const client = knex({
  client: 'pg', 
  connection: {
    host: 'localhost',
    port: 5432,
    user: 'hos_admin',
    password: 'hos_admin',
    database: 'hos',
    ssl: false
  },
  searchPath: ['public']
});

export default new KnexPgAdapter(client);