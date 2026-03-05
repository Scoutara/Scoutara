# SCOUTARA
### Scouting Instincts, Powered by AI, Backed with Data

AI-powered football scouting platform built with React + Supabase.

---

## Deploy to Vercel (Step-by-Step)

### 1. Install Node.js
Download and install from **nodejs.org** (LTS version). This gives you `npm`.

### 2. Upload to GitHub
1. Go to **github.com** and create a free account
2. Click **"New repository"** → name it `scoutara` → click **"Create repository"**
3. On the next screen, click **"uploading an existing file"**
4. Drag and drop ALL the files and folders from this project into the uploader
5. Click **"Commit changes"**

### 3. Deploy on Vercel
1. Go to **vercel.com** and sign up (use "Continue with GitHub")
2. Click **"Add New Project"**
3. Find your `scoutara` repo and click **"Import"**
4. Vercel auto-detects Vite — no settings to change
5. Click **"Deploy"**
6. Wait ~60 seconds — you'll get a live URL like `scoutara.vercel.app`

### 4. Custom Domain (optional)
1. Buy a domain at **namecheap.com** (e.g. `scoutara.com`, ~£10/yr)
2. In Vercel → your project → **Settings → Domains**
3. Add your domain and follow the DNS instructions

---

## Local Development

```bash
npm install
npm run dev
```
Open http://localhost:5173

## Build for production
```bash
npm run build
```

---

## Tech Stack
- **React 18** + Vite
- **Supabase** — Auth + PostgreSQL database
- **Claude AI** (Anthropic) — AI scouting reports & squad analysis

## Supabase Setup
The Supabase project URL and key are already configured in `src/App.jsx`.
Your database schema (players table + RLS policies) should already be set up.
