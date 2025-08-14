# An Even Faster Workflow for Publishing Teaching Materials

> 💡 **Note**
> 
> This software will be discussed in person on Thursday, August 14, 2025 at the [Summer Conference for Computer Studies and Mathematics Educators](https://cemc.uwaterloo.ca/workshops/educator-development/summer-conference-educators), organized by the [Centre for Education in Mathematics and Computing](https://www.cemc.uwaterloo.ca/).

**Workshop Description:**

Content management systems such as Edsby, Brightspace, Google Classroom... the list of third-party platforms we depend on as teachers to share information with our students is long. The user interfaces of these systems? Questionable, often requiring a time-consuming series of clicks and selections to publish even the simplest information. Further, it is often difficult to move your valuable content out of these systems.

In this session, the presenter will share a pre-configured publishing system that you control, can take away from the conference, and then run on your own computer to build modern, standards-compliant class websites.

In the session, optionally complete a series of “quests” to learn how to use this publishing workflow and get assistance from the presenter in setting up your own website on the spot. You will learn how to use Markdown-formatted text files to quickly publish a deeply linked, searchable website, with pages that can include “pretty-print” mathematical formulae and equations, code snippets, diagrams, animations, images, videos, PDF files, or any other type of document.

> 🏗️ **Tip**
>
> You can browse [an example of the type of output produced by this workflow here](https://aesthetic-bubblegum-622206.netlify.app). That site represents half of the author's Grade 10 Digital Tech course materials for the most recent school year.

> 💡 **Note**
> 
> For those with good memories, this is an update of the 2023 session titled “[A Rapid Workflow for Publishing CS Teaching Materials](https://teaching.russellgordon.ca/cemc/sccst-2023/a-rapid-workflow-for-publishing-cs-teaching-materials/)”, with new software, much less work involved to get a site up and running, and a better end-product. This new session is suitable for and useful for both mathematics and computer science teachers.

> 📘 **Info**  
> This documentation was generated using ChatGPT 4o and ChatGPT 5.

---

## 🚀 Quick Start (For Teachers)

### ✅ Prerequisites

- Install and open [Docker Desktop](https://www.docker.com/products/docker-desktop) (required)
   - A Docker account is not required. You can skip this step during installation.
- Install [Obsidian](https://obsidian.md/) (optional, but recommended for editing Markdown)
- **macOS users**, install [iTerm2](https://iterm2.com) for full 24-bit ANSI colour support in the colour scheme picker
- **Windows users**, you need [PowerShell 5.1 or later](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) (comes with Windows 10+; download if on an older version of Windows)
- [Create a **GitHub account**](https://github.com/join) (if you don’t have one already)
- [Create a **Netlify account**](https://app.netlify.com/signup) (if you don’t have one already)

> 💡 **TIP**
>
> Your computer's user account must have Administrator privileges to use this workflow. 

---

## 🖥 Opening a Command Prompt or Terminal

Before running the commands below, open a command-line interface:

**On macOS:**
1. Open **iTerm2** (recommended) or the built‑in **Terminal** app (find it in `Applications > Utilities`).
2. Use the `cd` command to change into the folder where you want to work. Example:
   ```bash
   cd "$HOME/Desktop" && mkdir "class-websites" && cd "class-websites" && pwd
   ```

**On Windows:**
1. Press `Windows + S` and type **PowerShell**.
2. Click **Windows PowerShell** to open it.
3. Use the `cd` command to change into the folder where you want to work. Example:
   ```powershell
   cd "$HOME\Desktop"; mkdir "class-websites"; cd "class-websites"; pwd
   ```

---

## 🐳 Step-by-Step: From Zero to Website

### 1. Get the launcher scripts from the Docker image

These scripts (`setup.sh` / `setup.bat`, `preview.sh` / `preview.bat`, `deploy.sh` / `deploy.bat`) are already inside the Docker image.

Run one of the following commands **in an empty folder** where you want to work:

**macOS / Linux (bash/zsh):**
```bash
docker run --rm -v "$PWD":/out rwhgrwhg/teaching-quartz:latest export-scripts
```

**Windows (PowerShell):**
```powershell
docker run --rm -v "${PWD}:/out" rwhgrwhg/teaching-quartz:latest export-scripts
```

This will place the launcher scripts into your current folder, ready to run.

---

### 2. Set up your course

On macOS/Linux:
```bash
./setup.sh
```

On Windows:
```powershell
.\setup.bat
```

This will:
- Offer to install an example course (recommended for first-time users)
- If you do not install the example course, it will:
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

On macOS/Linux:
```bash
./preview.sh ICS3U 1
```

On Windows:
```powershell
.\preview.bat ICS3U 1
```

This will:
- Combine content from shared folders and `section1`
- Build a live Quartz site into `courses/ICS3U/section1_output`
- Launch a local preview at:

👉 [http://localhost:8081](http://localhost:8081)

---

### 5. Publish your site (Deploy)

Once you’re happy with your preview, you can publish the site so students and others can see it.

On macOS/Linux:
```bash
./deploy.sh ICS3U 1
```

On Windows:
```powershell
.\deploy.bat ICS3U 1
```

This will:
- Package the built site for the chosen section
- Guide you through pushing it to a new GitHub repository (you’ll log into GitHub during this step)
- Allow you to link that repository to **Netlify**, which will host your site publicly
- Any future changes you make and push to GitHub will automatically trigger a rebuild in Netlify

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
├── preview.sh / preview.bat    # Build + preview a section site
├── setup.sh / setup.bat        # Run course setup wizard
├── deploy.sh / deploy.bat      # Deploy a built site
└── README.md
```

---

## 🛠️ Troubleshooting

| Problem | Solution |
|--------|----------|
| **Colour picker not showing correct colours** | If on macOS, make sure you are using [iTerm2](https://iterm2.com) instead of the default Terminal app for full colour support. |

---

## 🙏 Credits

- [Quartz](https://github.com/jackyzha0/quartz) by [Jacky Zhao](https://jzhao.xyz/)
- Docker integration and teacher-friendly workflow by [Russell Gordon](https://github.com/russellgordon)

---

## 📣 License

MIT License. Use, remix, and share freely — especially with other educators.
