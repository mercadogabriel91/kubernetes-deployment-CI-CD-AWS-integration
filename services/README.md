# Services Overview - NestJS/TypeScript

## Architecture

```
Client → Main API (NestJS) → Auxiliary Service (NestJS) → AWS (S3, Parameter Store)
```

## Services

### Main API (`services/main-api/`)
- **Port**: 3000 (default, configurable via PORT env var)
- **Framework**: NestJS + TypeScript
- **Role**: Public-facing API
- **Endpoints**:
  - `GET /buckets` - List S3 buckets
  - `GET /parameters` - List Parameter Store parameters
  - `GET /parameters/{name}` - Get specific parameter
  - `GET /health` - Health check

### Auxiliary Service (`services/auxiliary-service/`)
- **Port**: 3001 (default, configurable via PORT env var)
- **Framework**: NestJS + TypeScript
- **Role**: AWS integration service
- **Endpoints**:
  - `GET /aws/buckets` - List S3 buckets (internal)
  - `GET /aws/parameters` - List parameters (internal)
  - `GET /aws/parameters/{name}` - Get parameter (internal)
  - `GET /version` - Get service version
  - `GET /health` - Health check

## Local Development

### Prerequisites
- Node.js 20+ (with pnpm via corepack)
- pnpm (enabled via `corepack enable`)
- AWS credentials configured (`aws configure` or environment variables)

### Run Auxiliary Service Locally

```bash
cd services/auxiliary-service

# Enable pnpm (if not already enabled)
corepack enable

# Install dependencies
pnpm install

# Set environment variables
export VERSION=1.0.0
export AWS_DEFAULT_REGION=us-east-1

# Make sure AWS credentials are configured
# Option 1: AWS CLI
aws configure

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret

# Run in development mode
pnpm run start:dev

# Or build and run production
pnpm run build
pnpm run start:prod
```

**Service runs on http://localhost:3001**

### Run Main API Locally

```bash
cd services/main-api

# Enable pnpm (if not already enabled)
corepack enable

# Install dependencies
pnpm install

# Set environment variables
export VERSION=1.0.0
export AUXILIARY_SERVICE_URL=http://localhost:3001

# Run in development mode
pnpm run start:dev

# Or build and run production
pnpm run build
pnpm run start:prod
```

**Service runs on http://localhost:3000**

### Test Endpoints

```bash
# Test Main API
curl http://localhost:3000/buckets
curl http://localhost:3000/parameters
curl http://localhost:3000/parameters/kantox-challenge/app-version

# Test Auxiliary Service directly
curl http://localhost:3001/aws/buckets
curl http://localhost:3001/version
curl http://localhost:3001/health
```

## Docker Build

### Build Images

```bash
# Build Auxiliary Service
docker build -t auxiliary-service:1.0.0 services/auxiliary-service/

# Build Main API
docker build -t main-api:1.0.0 services/main-api/
```

### Run with Docker

```bash
# Run Auxiliary Service
docker run -p 3001:3001 \
  -e VERSION=1.0.0 \
  -e AWS_ACCESS_KEY_ID=your-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret \
  -e AWS_DEFAULT_REGION=us-east-1 \
  auxiliary-service:1.0.0

# Run Main API
docker run -p 3000:3000 \
  -e VERSION=1.0.0 \
  -e AUXILIARY_SERVICE_URL=http://host.docker.internal:3001 \
  main-api:1.0.0
```

### Docker Compose (Recommended)

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  auxiliary-service:
    build: ./services/auxiliary-service
    ports:
      - "3001:3001"
    environment:
      - VERSION=1.0.0
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}
    networks:
      - kantox-network

  main-api:
    build: ./services/main-api
    ports:
      - "3000:3000"
    environment:
      - VERSION=1.0.0
      - AUXILIARY_SERVICE_URL=http://auxiliary-service:3001
    depends_on:
      - auxiliary-service
    networks:
      - kantox-network

networks:
  kantox-network:
    driver: bridge
```

Run:
```bash
docker-compose up --build
```

## Environment Variables

### Main API
- `VERSION` - Service version (default: "1.0.0")
- `PORT` - Port to listen on (default: 3000)
- `AUXILIARY_SERVICE_URL` - URL of Auxiliary Service (default: "http://localhost:3001")

### Auxiliary Service
- `VERSION` - Service version (default: "1.0.0")
- `PORT` - Port to listen on (default: 3001)
- AWS credentials (via environment variables or IAM role):
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_DEFAULT_REGION`

## Response Format

### Main API Response Example
```json
{
  "buckets": ["my-bucket-1", "my-bucket-2"],
  "main_api_version": "1.0.0",
  "auxiliary_service_version": "1.0.0"
}
```

### Auxiliary Service Response Example
```json
{
  "buckets": ["my-bucket-1", "my-bucket-2"],
  "version": "1.0.0"
}
```

## Project Structure

### NestJS Structure
```
services/
├── main-api/
│   ├── src/
│   │   ├── main.ts              # Entry point
│   │   ├── app.module.ts        # Root module
│   │   ├── app.controller.ts    # API endpoints
│   │   └── auxiliary.service.ts # Service to call Auxiliary Service
│   ├── package.json
│   ├── tsconfig.json
│   └── Dockerfile
└── auxiliary-service/
    ├── src/
    │   ├── main.ts              # Entry point
    │   ├── app.module.ts        # Root module
    │   ├── app.controller.ts    # API endpoints
    │   └── aws.service.ts      # AWS SDK integration
    ├── package.json
    ├── tsconfig.json
    └── Dockerfile
```

## Development Tips

### Hot Reload
Both services support hot reload in development:
```bash
pnpm run start:dev
```

### TypeScript Compilation
Build TypeScript to JavaScript:
```bash
pnpm run build
```

### Linting
Fix linting issues:
```bash
pnpm run lint
```
