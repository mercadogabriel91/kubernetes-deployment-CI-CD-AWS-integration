import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Enable CORS
  app.enableCors();
  
  // CI/CD test - verifying automated build and deployment
  
  // Get port from environment variable (default: 3000)
  const portEnv = process.env.MAIN_API_PORT || process.env.PORT || '3000';
  const port = parseInt(portEnv, 10);
  const host = '0.0.0.0';
  
  if (isNaN(port) || port < 1 || port > 65535) {
    console.error(`Invalid port: ${portEnv}, using default 3000`);
    await app.listen(3000, host);
  } else {
    await app.listen(port, host);
  }
  console.log(`Main API is running on http://${host}:${port || 3000}`);
}

bootstrap();

