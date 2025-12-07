# Quick Start: NestJS Services

## 🚀 Get Started in 5 Minutes

### Prerequisites
- Node.js 20+ installed
- pnpm enabled (`corepack enable`)
- AWS credentials configured (`aws configure`)
- Docker (optional, for containerization)

---

## Option 1: Run Locally (Development)

### Step 1: Start Auxiliary Service

```bash
cd services/auxiliary-service

# Enable pnpm (if not already enabled)
corepack enable

# Install dependencies
pnpm install

# Set environment variables
export VERSION=1.0.0
export AWS_DEFAULT_REGION=us-east-1

# Run in development mode (hot reload)
pnpm run start:dev
```

**Expected output:**
```
[Nest] Starting Nest application...
Auxiliary Service is running on http://0.0.0.0:3001
```

### Step 2: Start Main API (New Terminal)

```bash
cd services/main-api

# Enable pnpm (if not already enabled)
corepack enable

# Install dependencies
pnpm install

# Set environment variables
export VERSION=1.0.0
export AUXILIARY_SERVICE_URL=http://localhost:3001

# Run in development mode (hot reload)
pnpm run start:dev
```

**Expected output:**
```
[Nest] Starting Nest application...
Main API is running on http://0.0.0.0:3000
```

### Step 3: Test Endpoints

**Terminal 3:**

```bash
# Test Main API - List Buckets
curl http://localhost:3000/buckets | jq

# Test Main API - List Parameters
curl http://localhost:3000/parameters | jq

# Test Main API - Get Specific Parameter
curl http://localhost:3000/parameters/kantox-challenge/app-version | jq

# Test health endpoints
curl http://localhost:3000/health | jq
curl http://localhost:3001/health | jq
```

---

## Option 2: Run with Docker Compose (Easier)

### One Command to Run Everything

```bash
cd services

# Set AWS credentials (if not already set)
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
export AWS_DEFAULT_REGION=us-east-1

# Build and run both services
docker-compose up --build
```

**Both services will start automatically!**

### Test Endpoints

```bash
# In another terminal
curl http://localhost:3000/buckets | jq
curl http://localhost:3000/parameters | jq
```

---

## 📋 Expected Responses

### GET http://localhost:3000/buckets
```json
{
  "buckets": ["my-bucket-1", "my-bucket-2"],
  "main_api_version": "1.0.0",
  "auxiliary_service_version": "1.0.0"
}
```

### GET http://localhost:5000/parameters
```json
{
  "parameters": [
    "/kantox-challenge/app-version",
    "/other/parameter"
  ],
  "main_api_version": "1.0.0",
  "auxiliary_service_version": "1.0.0"
}
```

### GET http://localhost:3000/parameters/kantox-challenge/app-version
```json
{
  "name": "/kantox-challenge/app-version",
  "value": "1.0.0",
  "type": "String",
  "main_api_version": "1.0.0",
  "auxiliary_service_version": "1.0.0"
}
```

---

## 🔧 Build for Production

### Build Individual Services

```bash
# Build Auxiliary Service
cd services/auxiliary-service
pnpm run build
# Output: dist/ directory

# Build Main API
cd ../main-api
pnpm run build
# Output: dist/ directory
```

### Build Docker Images

```bash
# Build Auxiliary Service
docker build -t auxiliary-service:1.0.0 services/auxiliary-service/

# Build Main API
docker build -t main-api:1.0.0 services/main-api/
```

---

## 🐛 Troubleshooting

### "Cannot find module" errors
```bash
# Make sure dependencies are installed
cd services/auxiliary-service
pnpm install

cd ../main-api
pnpm install
```

### "Connection refused" when Main API calls Auxiliary Service
- Make sure Auxiliary Service is running on port 3001
- Check `AUXILIARY_SERVICE_URL` environment variable
- For Docker: Use service name `http://auxiliary-service:3001`

### "Access Denied" from AWS
- Check AWS credentials: `aws configure list`
- Verify IAM permissions for S3 and Parameter Store
- Check AWS region is correct

### "Parameter not found"
Create a test parameter:
```bash
aws ssm put-parameter \
  --name "/kantox-challenge/app-version" \
  --value "1.0.0" \
  --type "String"
```

### Port already in use
```bash
# Check what's using the port
lsof -i :3000
lsof -i :3001

# Kill the process or change PORT environment variable
# Example: export PORT=8080
```

---

## 📁 Project Structure

```
services/
├── auxiliary-service/
│   ├── src/
│   │   ├── main.ts              # Entry point
│   │   ├── app.module.ts        # Root module
│   │   ├── app.controller.ts    # API endpoints
│   │   └── aws.service.ts      # AWS SDK integration
│   ├── package.json
│   ├── tsconfig.json
│   └── Dockerfile
├── main-api/
│   ├── src/
│   │   ├── main.ts              # Entry point
│   │   ├── app.module.ts        # Root module
│   │   ├── app.controller.ts    # API endpoints
│   │   └── auxiliary.service.ts # Service to call Auxiliary Service
│   ├── package.json
│   ├── tsconfig.json
│   └── Dockerfile
└── docker-compose.yml
```

---

## ✅ Next Steps

Once services work locally:
1. ✅ Test all endpoints
2. ✅ Build Docker images
3. ✅ Push to ECR (you know how!)
4. ✅ Create Kubernetes manifests
5. ✅ Deploy to Kubernetes

---

## 💡 Development Tips

### Hot Reload
Both services support hot reload:
```bash
pnpm run start:dev
```
Changes to `.ts` files will automatically restart the server.

### TypeScript Compilation
```bash
pnpm run build
```
Compiles TypeScript to JavaScript in `dist/` directory.

### Linting
```bash
pnpm run lint
```
Fixes linting issues automatically.

---

**You're all set!** Since you know NestJS, this should feel familiar. The architecture is the same as before, just using TypeScript instead of Python! 🚀
