import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Enable CORS
  app.enableCors();
  
  // Get port from environment variable (default: 3001)
  const port = process.env.AUXILIARY_SERVICE_PORT || process.env.PORT || 3001;
  
  await app.listen(port);
  console.log(`Auxiliary Service is running on http://0.0.0.0:${port}`);
}

bootstrap();

