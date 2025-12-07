import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Enable CORS
  app.enableCors();
  
  // Get port from environment variable (default: 3000)
  const port = process.env.MAIN_API_PORT || process.env.PORT || 3000;
  
  await app.listen(port);
  console.log(`Main API is running on http://0.0.0.0:${port}`);
}

bootstrap();

