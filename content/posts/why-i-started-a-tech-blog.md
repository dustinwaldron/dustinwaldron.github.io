---
title: "Why I Started a Tech Blog (and How You Can Too with Hugo + GitHub Pages)"
date: "2025-11-01T11:00:00-04:00"
description: "My first blog post — plus a guide to setting up your own Hugo blog on GitHub Pages."
tags:
  - github
  - engineering
  - blogging
---

## Why I Started This Blog

As engineers, we spend a lot of time building, experimenting, and solving problems. But too often, those lessons stay hidden inside project folders, Slack threads, or our own heads.

Starting this blog was my way to change that — to **document my projects**, **share what I learn**, and hopefully **inspire others to build cool things**.

### 1. Document Projects
Writing about a project forces you to clarify your thinking. It’s easy to move on to the next shiny idea, but documentation helps future-you (and others) revisit, maintain, and extend your work.

### 2. Share Knowledge
Every engineer learns differently, and your perspective might be the one that helps someone finally understand a tricky concept. Sharing knowledge strengthens the community and makes tech more accessible.

### 3. Inspire Builders
We all got into this field because we love building. When I read other engineers’ blogs, I get inspired to try new stacks, frameworks, or even just better ways of thinking. I hope this blog does the same for someone else.

---

## How I Built This Blog: Hugo + GitHub Pages

If you’ve been thinking about starting your own tech blog, you can do it in an afternoon. Here’s the path I took to get this one up and running.

### Step 1: Install Hugo

Hugo is a static site generator written in Go. It’s fast, flexible, and perfect for developer blogs.

```bash
# for mac
brew install hugo
# or for Windows
choco install hugo-extended
```

Check your install:
```bash
hugo version
```

### Step 2: Create a New Site

```bash
hugo new site my-tech-blog
cd my-tech-blog
```

### Step 3: Add a Theme

Pick a theme you like from [themes.gohugo.io](https://themes.gohugo.io/).

Example:

```bash
git submodule add https://github.com/adityatelange/hugo-PaperMod
echo 'theme = "PaperMod"' >> hugo.toml
```

### Step 4: Add Your First Post

```bash
hugo new posts/your-awesome-post.md
```

Open the file in your editor, write your first post and save.

### Step 5: Test Locally

```bash
hugo server
```

Then visit [http://localhost:1313](http://localhost:1313) to preview your blog.

### Step 6: Push to GitHub

Initialize a repo and push:

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/yourusername/my-tech-blog.git
git push -u origin main
```

### Step 7: Deploy with GitHub Pages

You can deploy using a GitHub Actions workflow:

Create `.github/workflows/hugo.yml`:

```yaml
name: Build and deploy
on:
  push:
    branches:
    - main # Set a branch to deploy
  pull_request:

jobs:
  deploy:
    runs-on: ubuntu-24.04
    concurrency:
      group: ${{ github.workflow }}-${{ github.ref }}
    steps:
    - uses: actions/checkout@v4
      with:
        submodules: true # Fetch Hugo themes (true OR recursive)
        fetch-depth: 0 # Fetch all history for .GitInfo and .Lastmod

    - name: Setup Hugo
      uses: peaceiris/actions-hugo@v3
      with:
        hugo-version: '0.119.0'
        # extended: true

    - name: Build
      run: hugo --minify

    - name: Deploy
      uses: peaceiris/actions-gh-pages@v3
      if: github.ref == 'refs/heads/main'
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./public
```

Push the workflow, and your blog will auto-deploy to `https://yourusername.github.io/my-tech-blog/`.

---

## Final Thoughts

Blogging as a developer isn’t just about writing — it’s about **creating a living record of your journey**.  
It’s a way to give back, stay accountable, and connect with others who love to build.

If you’ve ever thought, *“I should start a blog,”* — take this as your nudge.  
Start small, share your process, and let others learn alongside you.

Happy building!