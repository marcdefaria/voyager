#!/bin/bash
set -e

PROJECT_ID="voyager-staging-f3e0f"
REGION="europe-west2"
SERVICE="voyager-server"
IMAGE="gcr.io/$PROJECT_ID/$SERVICE"

echo "==> Deploying to STAGING ($PROJECT_ID)"

# Set active project
gcloud config set project $PROJECT_ID

# Build & push container
echo "==> Building image..."
gcloud builds submit ./server --tag $IMAGE

# Deploy to Cloud Run
echo "==> Deploying to Cloud Run..."
gcloud run deploy $SERVICE \
  --image $IMAGE \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --set-secrets="ANTHROPIC_API_KEY=ANTHROPIC_API_KEY:latest" \
  --set-env-vars="MODEL=claude-sonnet-4-6" \
  --memory=512Mi \
  --min-instances=0 \
  --max-instances=2

# Deploy Flutter web to Firebase Hosting
echo "==> Building Flutter web..."
cd app
flutter build web --release
cd ..

echo "==> Deploying to Firebase Hosting..."
firebase deploy --only hosting --project $PROJECT_ID

echo ""
echo "✓ Staging deployed"
echo "  API:  https://$SERVICE-<hash>-nw.a.run.app"
echo "  Web:  https://$PROJECT_ID.web.app"
