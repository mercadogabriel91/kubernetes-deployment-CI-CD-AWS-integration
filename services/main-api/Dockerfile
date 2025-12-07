FROM node:20-alpine AS builder

# Install pnpm (pin version to match local)
RUN corepack enable && corepack prepare pnpm@8.15.0 --activate

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./
COPY tsconfig.json ./
COPY nest-cli.json ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY src ./src

# Build the application
RUN pnpm run build

# Production stage
FROM node:20-alpine

# Install pnpm (pin version to match local)
RUN corepack enable && corepack prepare pnpm@8.15.0 --activate

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install production dependencies only
RUN pnpm install --frozen-lockfile --prod

# Copy built application from builder
COPY --from=builder /app/dist ./dist

# Expose port
EXPOSE 3000

# Run the application
CMD ["node", "dist/main"]
