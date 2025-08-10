import { Translation } from "./definition"

export default {
  propertyDefaults: {
    title: "Névtelen",
    description: "Nincs leírás",
  },
  components: {
    callout: {
      note: "Jegyzet",
      abstract: "Abstract",
      info: "Információ",
      todo: "Tennivaló",
      tip: "Tipp",
      success: "Siker",
      question: "Kérdés",
      warning: "Figyelmeztetés",
      failure: "Hiba",
      danger: "Veszély",
      bug: "Bug",
      example: "Példa",
      quote: "Idézet",
    },
    backlinks: {
      title: "Mikor csináltuk ezt?",
      noBacklinksFound: "Még nem tárgyaltuk az órán.",
    },
    themeToggle: {
      lightMode: "Világos mód",
      darkMode: "Sötét mód",
    },
    explorer: {
      title: "Fájlböngésző",
    },
    footer: {
      createdWith: "Készítve ezzel:",
    },
    graph: {
      title: "Grafikonnézet",
    },
    recentNotes: {
      title: "Legutóbbi jegyzetek",
      seeRemainingMore: ({ remaining }) => `${remaining} további megtekintése →`,
    },
    transcludes: {
      transcludeOf: ({ targetSlug }) => `${targetSlug} áthivatkozása`,
      linkToOriginal: "Hivatkozás az eredetire",
    },
    search: {
      title: "Keresés",
      searchBarPlaceholder: "Keress valamire",
    },
    tableOfContents: {
      title: "Navigáljon ezen az oldalon",
    },
    contentMeta: {
      readingTime: ({ minutes }) => `${minutes} perces olvasás`,
    },
  },
  pages: {
    rss: {
      recentNotes: "Legutóbbi jegyzetek",
      lastFewNotes: ({ count }) => `Legutóbbi ${count} jegyzet`,
    },
    error: {
      title: "Nem található",
      notFound: "Ez a lap vagy privát vagy nem létezik.",
      home: "Vissza a kezdőlapra",
    },
    folderContent: {
      folder: "Mappa",
      itemsUnderFolder: ({ count }) => `Ebben a mappában ${count} elem található.`,
    },
    tagContent: {
      tag: "Címke",
      tagIndex: "Címke index",
      itemsUnderTag: ({ count }) => `${count} elem található ezzel a címkével.`,
      showingFirst: ({ count }) => `Első ${count} címke megjelenítve.`,
      totalTags: ({ count }) => `Összesen ${count} címke található.`,
    },
  },
} as const satisfies Translation
