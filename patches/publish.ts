import { QuartzFilterPlugin } from "../types"

/**
 * Decides whether a page reaches the built site, from a `publish:` flag.
 *
 * Quartz ships two filters and neither says what a teacher means:
 *
 *   - RemoveDrafts publishes everything except `draft: true`. The word
 *     "draft" reads as "unfinished", not "not visible to students", and the
 *     polarity is backwards from how a teacher talks: they say a page IS or
 *     ISN'T published, never that it is or isn't a draft.
 *   - ExplicitPublish publishes only `publish: true` — the right word, but it
 *     flips the default. In the example course 60 of 225 pages carry no flag
 *     at all, including every curriculum page, and every one of them would
 *     silently vanish from the site.
 *
 * So: the teacher's word, today's default. A page is published unless it says
 * `publish: false`. Forgetting the flag leaves a page visible, which is a far
 * kinder mistake than a page disappearing without anybody noticing.
 *
 * Strings are accepted as well as booleans because YAML quoting varies and a
 * quoted "false" plainly means false.
 */
export const PublishFlag: QuartzFilterPlugin = () => ({
  name: "PublishFlag",
  shouldPublish(_ctx, [_tree, vfile]) {
    const flag = vfile.data?.frontmatter?.publish
    return !(flag === false || flag === "false")
  },
})
