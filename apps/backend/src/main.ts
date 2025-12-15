import { HttpAdapterHost, NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { CodeErrorFilter } from './common/code-error.filter';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import cookieParser from 'cookie-parser';
import type { RedocOptions } from 'nestjs-redox';
import { RedocModule } from '@jozefazz/nestjs-redoc';
import { ACCESS_TOKEN_AUTH } from './config/constants';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);
  app.enableCors({
    origin: configService.get<string>('ALLOWED_HOSTS')?.split(',') ?? [],
    credentials: true,
  });
  app.use(cookieParser(configService.getOrThrow('COOKIE_SECRET')));
  const { httpAdapter } = app.get(HttpAdapterHost);
  app.useGlobalFilters(new CodeErrorFilter(httpAdapter));

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
    }),
  );

  const config = new DocumentBuilder()
    .setTitle('HOS API')
    .setDescription('HOS API documentation (app for hospital)')
    .setVersion('1.0')
    .addTag('')
    .addBearerAuth(
      { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      ACCESS_TOKEN_AUTH,
    )
    .build();
  // reflects to all endpoints
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);
  const redocOptions: RedocOptions = {
    // options
  };
  await RedocModule.setup('redoc', app, document, redocOptions);
  await app.listen(configService.get<string>('PORT') ?? 3000);
}
bootstrap().catch(console.error);
