# An Even Faster Workflow for Publishing Teaching Materials

> 💡 **Note**
> 
> This software will be discussed in person on Thursday, August 13, 2025 at the [Summer Conference for Computer Studies and Mathematics Educators](https://cemc.uwaterloo.ca/workshops/educator-development/summer-conference-educators), organized by the [Centre for Education in Mathematics and Computing](https://www.cemc.uwaterloo.ca/).

**Workshop Description:**

Content management systems such as Edsby, Brightspace, Google Classroom... the list of third-party platforms we depend on as teachers to share information with our students is long. The user interfaces of these systems? Questionable, often requiring a time-consuming series of clicks and selections to publish even the simplest information. Further, it is often difficult to move your valuable content out of these systems.

In this session, the presenter will share a pre-configured publishing system that you control, can take away from the conference, and then run on your own computer to build modern, standards-compliant class websites.

In the session, optionally complete a series of “quests” to learn how to use this publishing workflow and get assistance from the presenter in setting up your own website on the spot. You will learn how to use Markdown-formatted text files to quickly publish a deeply linked, searchable website, with pages that can include “pretty-print” mathematical formulae and equations, code snippets, diagrams, animations, images, videos, PDF files, or any other type of document.

> 📘 **Info**  
> This documentation was generated using ChatGPT 4o.

---

## 🚀 Quick Start (For Teachers)

### ✅ Prerequisites

- Install [Docker Desktop](https://www.docker.com/products/docker-desktop) (required)
- Install [Obsidian](https://obsidian.md/) (optional, but recommended for editing Markdown)
- *(macOS users)* Install [iTerm2](https://iterm2.com) for full 24-bit ANSI colour support in the colour scheme picker

> 💡 No need to install Node.js, Python, or Quartz. Everything runs inside Docker!

---

## 🐳 Step-by-Step: From Markdown to Website

### 1. Clone this repository

```bash
git clone https://github.com/russellgordon/containerized-quartz-for-teachers.git
cd containerized-quartz-for-teachers
```

---

### 2. Set up your course

```bash
./setup.sh
```

This will:
- Prompt you for the course code, name, and number of sections
- Let you select shared folders (e.g., “Exercises”, “Examples”)
- Let you choose a colour scheme for each section with a live swatch preview
- Create everything under `./courses/<CourseCode>` ready for editing

---

### 3. Edit content in Obsidian

Open the `courses/` folder in Obsidian or your favorite Markdown editor.

Structure:
```
courses/
  ICS3U/
    section1/
    section2/
    Examples/
    Exercises/
    ...
```

---

### 4. Preview your site

```bash
./run.sh ICS3U 1
```

This will:
- Combine content from shared folders and `section1`
- Build a live Quartz site into `courses/ICS3U/section1_output`
- Launch a local preview at:

👉 [http://localhost:8081](http://localhost:8081)

---

## ⚙️ Optional Flags

| Flag | Description |
|------|-------------|
| `--reset-hidden` | Re-prompt to choose which folders/files to **hide from the Explorer sidebar** |
| `--include-social-media-previews` | Enable [Quartz CustomOgImages](https://github.com/jackyzha0/quartz#plugin-customogimages) to generate Open Graph images for pages (slower builds) |

Example:

```bash
./run.sh ICS3U 1 --reset-hidden --include-social-media-previews
```

---

## 🔧 What’s Inside the Docker Image?

The container includes:

- Python 3.11
- Node.js 20
- `python-frontmatter`
- Quartz v4.5.0 (cloned into `/opt/quartz`)
- Custom scripts to automate course setup and builds
- Port 8081 exposed for preview

Teacher content is bind-mounted at `/teaching/courses`.

---

## 🧼 File Structure

```
containerized-quartz-for-teachers/
├── courses/                    # Teacher-created content goes here
│   └── ICS3U/
│       ├── section1/
│       ├── section2/
│       ├── Examples/
│       └── Exercises/
├── scripts/
│   ├── setup_course.py         # Wizard to scaffold course + folders + colour schemes
│   └── build_site.py           # Builds site, applies filters, runs preview
├── Dockerfile                  # Defines container image
├── run.sh                      # Build + preview a section site
├── setup.sh                    # Run course setup wizard
└── README.md
```

---

## 🧠 Tips for Power Users

- You can modify Quartz’s layout or config files directly in the output folder (`section1_output/`) if needed.
- Add `createdForSection1: 2025-09-08` frontmatter to any Markdown file to make it **only appear in Section 1**.
- Use image/video/asset files directly inside folders and Quartz will include them in the build.

---

## 🛠️ Troubleshooting

| Problem | Solution |
|--------|----------|
| **Port 8081 already in use** | Close other Quartz tabs or processes. Or change the port inside `build_site.py`. |
| **Changes not showing up** | Rerun `./run.sh ...` to rebuild. Quartz does not always detect all file changes. |
| **File not appearing in Explorer sidebar** | Check if it was marked hidden (`hidden_explorer_components.json`). Use `--reset-hidden` to reselect. |
| **Colour picker not showing correct colours** | If on macOS, make sure you are using [iTerm2](https://iterm2.com) instead of the default Terminal app for full colour support. |

---

## 🙏 Credits

- [Quartz](https://github.com/jackyzha0/quartz) by [Jacky Zhao](https://jzhao.xyz/)
- Docker integration and teacher-friendly workflow by [Russell Gordon](https://github.com/russellgordon)

---

## 📣 License

MIT License. Use, remix, and share freely — especially with other educators.
