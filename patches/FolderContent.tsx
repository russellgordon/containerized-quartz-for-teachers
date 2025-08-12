import { QuartzComponent, QuartzComponentConstructor, QuartzComponentProps } from "../types"

import style from "../styles/listPage.scss"
import { PageList, SortFn } from "../PageList"
import { Root } from "hast"
import { htmlToJsx } from "../../util/jsx"
import { i18n } from "../../i18n"
import { QuartzPluginData } from "../../plugins/vfile"
import { ComponentChildren } from "preact"
import { concatenateResources } from "../../util/resources"
import { FileTrieNode } from "../../util/fileTrie"

interface FolderContentOptions {
  /**
   * Whether to display number of folders
   */
  showFolderCount: boolean
  showSubfolders: boolean
  sort?: SortFn
}

const defaultOptions: FolderContentOptions = {
  showFolderCount: false,
  showSubfolders: true,
}

export default ((opts?: Partial<FolderContentOptions>) => {
  const options: FolderContentOptions = { ...defaultOptions, ...opts }
  let trie: FileTrieNode<
    QuartzPluginData & {
      slug: string
      title: string
      filePath: string
    }
  >

  const FolderContent: QuartzComponent = (props: QuartzComponentProps) => {
    const { tree, fileData, allFiles, cfg } = props

    // Build a trie of all files (once)
    if (!trie) {
      trie = new FileTrieNode([])
      allFiles.forEach((file) => {
        if (file.frontmatter) {
          trie.add({
            ...file,
            slug: file.slug!,
            title: file.frontmatter.title,
            filePath: file.filePath!,
          })
        }
      })
    }

    const folder = trie.findNode(fileData.slug!.split("/"))
    if (!folder) {
      return null
    }

    const allPagesInFolder: QuartzPluginData[] =
      folder.children
        .map((node) => {
          // regular file, proceed
          if (node.data) {
            return node.data
          }

          if (node.isFolder && options.showSubfolders) {
            // folders that dont have data need synthetic files
            const getMostRecentDates = (): QuartzPluginData["dates"] => {
              let maybeDates: QuartzPluginData["dates"] | undefined = undefined
              for (const child of node.children) {
                if (child.data?.dates) {
                  // compare all dates and assign to maybeDates if its more recent or its not set
                  if (!maybeDates) {
                    maybeDates = child.data.dates
                  } else {
                    if (child.data.dates.created > maybeDates.created) {
                      maybeDates.created = child.data.dates.created
                    }

                    if (child.data.dates.modified > maybeDates.modified) {
                      maybeDates.modified = child.data.dates.modified
                    }

                    if (child.data.dates.published > maybeDates.published) {
                      maybeDates.published = child.data.dates.published
                    }
                  }
                }
              }
              return (
                maybeDates ?? {
                  created: new Date(),
                  modified: new Date(),
                  published: new Date(),
                }
              )
            }

            return {
              slug: node.slug,
              dates: getMostRecentDates(),
              frontmatter: {
                title: node.displayName,
                tags: [],
              },
            }
          }
        })
        .filter((page) => page !== undefined) ?? []

    const cssClasses: string[] = fileData.frontmatter?.cssclasses ?? []
    const classes = cssClasses.join(" ")
    const listProps = {
      ...props,
      sort: options.sort,
      allFiles: allPagesInFolder,
    }

    const content = (
      (tree as Root).children.length === 0
        ? fileData.description
        : htmlToJsx(fileData.filePath!, tree)
    ) as ComponentChildren

    // Read frontmatter flag `renderFolderPages` with sensible defaults
    const rawFlag = (fileData.frontmatter as any)?.renderFolderPages
    const shouldRenderPageList =
      rawFlag === undefined
        ? true
        : typeof rawFlag === "boolean"
          ? rawFlag
          : typeof rawFlag === "string"
            ? !/^(false|no|off|0)$/i.test(rawFlag.trim())
            : Boolean(rawFlag)

    return (
      <div class="popover-hint">
        <article class={classes}>{content}</article>
        {shouldRenderPageList && (
          <div class="page-listing">
            {options.showFolderCount && (
              <p>
                {i18n(cfg.locale).pages.folderContent.itemsUnderFolder({
                  count: allPagesInFolder.length,
                })}
              </p>
            )}
            <div>
              <PageList {...listProps} />
            </div>
          </div>
        )}
      </div>
    )
  }

  FolderContent.css = concatenateResources(style, PageList.css)
  return FolderContent
}) satisfies QuartzComponentConstructor
