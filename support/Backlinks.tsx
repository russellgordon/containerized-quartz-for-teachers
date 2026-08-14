import { QuartzComponent, QuartzComponentConstructor, QuartzComponentProps } from "./types"
import style from "./styles/backlinks.scss"
import { resolveRelative, simplifySlug } from "../util/path"
import { i18n } from "../i18n"
import { classNames } from "../util/lang"
import OverflowListFactory from "./OverflowList"

interface BacklinksOptions {
  hideWhenEmpty: boolean
}

const defaultOptions: BacklinksOptions = {
  hideWhenEmpty: true,
}

export default ((opts?: Partial<BacklinksOptions>) => {
  const options: BacklinksOptions = { ...defaultOptions, ...opts }
  const { OverflowList, overflowListAfterDOMLoaded } = OverflowListFactory()

  const Backlinks: QuartzComponent = ({
    fileData,
    allFiles,
    displayClass,
    cfg,
  }: QuartzComponentProps) => {
    const slug = simplifySlug(fileData.slug!)

    // "When did we do this?" answers which LESSONS touched this page. Two
    // kinds of page reference every curriculum expectation by
    // construction — the Curriculum index, which transcludes all of them,
    // and the generated Curriculum Coverage map, which links all of them.
    // Listed as backlinks they appear on every expectation page, so they
    // carry no information and push the real answer down the list.
    //
    // The rule is structural rather than a list of titles: anything
    // inside the curriculum folder, plus the generated map. Both are
    // written in by the build (CQ4T-STRUCTURAL-ANCHOR), which knows the
    // folder's real name — teachers rename it.
    // CQ4T-STRUCTURAL-ANCHOR: do not remove; build_site.py rewrites this line
    const structural = new Set<string>([""])
    const isStructural = (fileSlug: string): boolean => {
      if (structural.has(fileSlug)) {
        return true
      }
      const folder = fileSlug.split("/")[0]
      return structural.has(folder)
    }

    const backlinkFiles = allFiles.filter(
      (file) => file.links?.includes(slug) && !isStructural(simplifySlug(file.slug!)),
    )
    const excludeBacklinks = fileData.frontmatter?.excludeBacklinks
    if (options.hideWhenEmpty && backlinkFiles.length == 0) {
      return null
    }
    return (
      <div>
      {excludeBacklinks ? (<div></div>) : (
      <div class={classNames(displayClass, "backlinks")}>
        <h3>{i18n(cfg.locale).components.backlinks.title}</h3>
        <OverflowList>
          {backlinkFiles.length > 0 ? (
            backlinkFiles.map((f) => (
              <li>
                <a href={resolveRelative(fileData.slug!, f.slug!)} class="internal">
                  {f.frontmatter?.title}
                </a>
              </li>
            ))
          ) : (
            <li>{i18n(cfg.locale).components.backlinks.noBacklinksFound}</li>
          )}
        </OverflowList>
      </div>
      )}
      </div>
    )
  }

  Backlinks.css = style
  Backlinks.afterDOMLoaded = overflowListAfterDOMLoaded

  return Backlinks
}) satisfies QuartzComponentConstructor
