import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Enable CORS
  app.enableCors();
  
  // Get port from environment variable (default: 3001)
  const portEnv = process.env.AUXILIARY_SERVICE_PORT || process.env.PORT || '3001';
  const port = parseInt(portEnv, 10);
  const host = '0.0.0.0';
  
  if (isNaN(port) || port < 1 || port > 65535) {
    console.error(`Invalid port: ${portEnv}, using default 3001`);
    await app.listen(3001, host);
  } else {
    await app.listen(port, host);
  }
  console.log(`Auxiliary Service is running on http://${host}:${port || 3001}`);
}

bootstrap();

