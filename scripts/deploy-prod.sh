#!/bin/bash
set -e

PROJECT_ID="voyager-prod-e632b"
REGION="europe-west2"
SERVICE="voyager-server"
IMAGE="gcr.io/$PROJECT_ID/$SERVICE"

echo "==> Deploying to PRODUCTION ($PROJECT_ID)"
read -p "Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

gcloud config set project $PROJECT_ID

echo "==> Building image..."
gcloud builds submit ./server --tag $IMAGE

echo "==> Deploying to Cloud Run..."
gcloud run deploy $SERVICE \
  --image $IMAGE \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --set-secrets="ANTHROPIC_API_KEY=ANTHROPIC_API_KEY:latest" \
  --set-env-vars="MODEL=claude-opus-4-6" \
  --memory=512Mi \
  --min-instances=0 \
  --max-instances=10

echo "==> Building Flutter web..."
cd app
flutter build web --release
cd ..

echo "==> Deploying to Firebase Hosting..."
firebase deploy --only hosting --project $PROJECT_ID

echo ""
echo "✓ Production deployed"
