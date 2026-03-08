# Voyager

A holiday planning assistant powered by Claude AI. Chat naturally about your trip and watch your plan take shape in real time.

## What it does

Voyager is a conversational travel planner. You describe your ideal holiday and the AI guides you through the details — destination, dates, budget, accommodation, activities — building a structured plan as you chat.

## Stack

- **Frontend** — Flutter web app
- **Backend** — Node.js / Express API deployed on Cloud Run
- **AI** — Claude (Anthropic) via the `@anthropic-ai/sdk`
- **Hosting** — Firebase Hosting (frontend), Google Cloud Run (backend)

## Project structure

```
app/        Flutter frontend
server/     Express API
scripts/    Deployment helpers
Dockerfile  Cloud Run container
```

## Running locally

**Backend**
```bash
cd server
npm install
node index.js
```

**Frontend**
```bash
cd app
flutter run -d chrome --dart-define=API_URL=http://localhost:3000
```

## Deployment

The backend is containerised and deployed to Cloud Run. The frontend is built and deployed to Firebase Hosting.

```bash
# Deploy backend
gcloud builds submit --tag gcr.io/<project>/voyager-server
gcloud run deploy voyager-server --image gcr.io/<project>/voyager-server

# Deploy frontend
flutter build web --dart-define=API_URL=<cloud-run-url>
firebase deploy
```
