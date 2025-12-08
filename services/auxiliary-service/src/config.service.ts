import { Injectable, OnModuleInit, Logger } from "@nestjs/common";
import { AwsService } from "./aws.service";

@Injectable()
export class ConfigService implements OnModuleInit {
  private readonly logger = new Logger(ConfigService.name);
  private config: Map<string, string> = new Map();

  constructor(private readonly awsService: AwsService) {}

  async onModuleInit() {
    await this.loadConfigFromParameterStore();
  }

  private async loadConfigFromParameterStore() {
    try {
      this.logger.log("Loading configuration from AWS Parameter Store...");

      // Load configuration parameters
      const parametersToLoad = [
        "/k-challenge/auxiliary-service/port",
        "/k-challenge/app-version",
        "/k-challenge/environment",
      ];

      for (const paramName of parametersToLoad) {
        try {
          const param = await this.awsService.getParameter(paramName);
          const key = paramName.split("/").pop() || paramName;
          this.config.set(key, param.Value);
          this.logger.log(`Loaded ${paramName}: ${param.Value}`);
        } catch (error: any) {
          if (error.name === "ParameterNotFound") {
            this.logger.warn(
              `Parameter ${paramName} not found, using environment variable or default`
            );
          } else {
            this.logger.error(`Failed to load ${paramName}: ${error.message}`);
          }
        }
      }

      // Set environment variables from Parameter Store (for backward compatibility)
      if (this.config.has("port")) {
        process.env.AUXILIARY_SERVICE_PORT = this.config.get("port")!;
        process.env.PORT = this.config.get("port")!;
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
      process.env.AUXILIARY_SERVICE_PORT ||
      process.env.PORT ||
      "3001";
    return parseInt(portEnv, 10);
  }

  getVersion(): string {
    return this.get("app-version") || process.env.VERSION || "1.0.0";
  }
}
