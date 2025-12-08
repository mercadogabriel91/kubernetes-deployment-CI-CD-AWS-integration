import { Injectable, OnModuleInit, Logger } from "@nestjs/common";
import { HttpService } from "@nestjs/axios";
import { firstValueFrom } from "rxjs";

@Injectable()
export class ConfigService implements OnModuleInit {
  private readonly logger = new Logger(ConfigService.name);
  private config: Map<string, string> = new Map();

  constructor(private readonly httpService: HttpService) {}

  async onModuleInit() {
    await this.loadConfigFromParameterStore();
  }

  private async loadConfigFromParameterStore() {
    try {
      this.logger.log(
        "Loading configuration from AWS Parameter Store via Auxiliary Service..."
      );

      // Get Auxiliary Service URL from environment (set by Kubernetes ConfigMap or default)
      const auxiliaryServiceUrl =
        process.env.AUXILIARY_SERVICE_URL || "http://auxiliary-service:3001";

      // Load configuration parameters via Auxiliary Service
      const parametersToLoad = [
        "/k-challenge/main-api/port",
        "/k-challenge/auxiliary-service/url",
        "/k-challenge/app-version",
        "/k-challenge/environment",
      ];

      for (const paramName of parametersToLoad) {
        try {
          const response = await firstValueFrom(
            this.httpService.get(
              `${auxiliaryServiceUrl}/aws/parameters${paramName}`
            )
          );

          const key = paramName.split("/").pop() || paramName;
          this.config.set(key, response.data.value);
          this.logger.log(`Loaded ${paramName}: ${response.data.value}`);
        } catch (error: any) {
          this.logger.warn(`Failed to load ${paramName}: ${error.message}`);
        }
      }

      // Set environment variables from Parameter Store (for backward compatibility)
      if (this.config.has("port")) {
        process.env.MAIN_API_PORT = this.config.get("port")!;
        process.env.PORT = this.config.get("port")!;
      }
      if (this.config.has("url")) {
        process.env.AUXILIARY_SERVICE_URL = this.config.get("url")!;
      }
      if (this.config.has("app-version")) {
        process.env.VERSION = this.config.get("app-version")!;
      }

      this.logger.log("Configuration loaded successfully from Parameter Store");
    } catch (error: any) {
      this.logger.error(
        `Failed to load configuration from Parameter Store: ${error.message}`
      );
      this.logger.warn("Falling back to environment variables or defaults");
    }
  }

  get(key: string): string | undefined {
    return this.config.get(key) || process.env[key];
  }

  getPort(): number {
    const portEnv =
      this.get("port") ||
      process.env.MAIN_API_PORT ||
      process.env.PORT ||
      "3000";
    return parseInt(portEnv, 10);
  }

  getAuxiliaryServiceUrl(): string {
    return (
      this.get("url") ||
      process.env.AUXILIARY_SERVICE_URL ||
      "http://auxiliary-service:3001"
    );
  }

  getVersion(): string {
    return this.get("app-version") || process.env.VERSION || "1.0.0";
  }
}
