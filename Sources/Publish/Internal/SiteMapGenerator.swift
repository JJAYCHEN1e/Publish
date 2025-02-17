/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Plot

struct SiteMapGenerator<Site: Website> {
    let excludedPaths: Set<Path>
    let indentation: Indentation.Kind?
    let context: PublishingContext<Site>

    func generate() throws {
        let sections = context.sections.sorted {
            $0.id.rawValue < $1.id.rawValue
        }

        let pages = context.pages.values.sorted {
            $0.path < $1.path
        }

        let siteMap = makeSiteMap(for: sections, pages: pages, site: context.site)
        let xml = siteMap.render(indentedBy: indentation)
        let file = try context.createOutputFile(at: "sitemap.xml")
        try file.write(xml)
    }
}

private extension SiteMapGenerator {
    func shouldIncludePath(_ path: Path) -> Bool {
        !excludedPaths.contains(where: {
            path.string.hasPrefix($0.string)
        })
    }

    func makeSiteMap(for sections: [Section<Site>], pages: [Page], site: Site) -> SiteMap {
        SiteMap(
            .forEach(sections) { section in
                guard shouldIncludePath(section.path) else {
                    return .empty
                }

                return .group(
                    .url(
                        .loc(site.url(for: section)),
                        .changefreq(.daily),
                        .priority(1.0),
                        .lastmod(max(
                            section.lastModified,
                            section.lastItemModificationDate ?? .distantPast
                        ))
                    ),
                    .forEach(section.items) { item in
                        guard shouldIncludePath(item.path) else {
                            return .empty
                        }

                        return .url(
                            .loc(site.url(for: item)),
                            .changefreq(.monthly),
                            .priority(0.5),
                            .lastmod(item.lastModified)
                        )
                    }
                )
            },
            .forEach(pages) { page in
                guard shouldIncludePath(page.path) else {
                    return .empty
                }

                return .url(
                    .loc(site.url(for: page)),
                    .changefreq(.monthly),
                    .priority(0.5),
                    .lastmod(page.lastModified)
                )
            }
        )
    }
}

internal extension SiteMapGenerator where Site: MultiLanguageWebsite {
    func generate() throws {
        let sections = context.sections.sorted {
            $0.id.rawValue < $1.id.rawValue
        }

        let pages = context.pages.values.sorted {
            $0.path < $1.path
        }

        let siteMap = makeSiteMap(for: sections, pages: pages, site: context.site)
        let xml = siteMap.render(indentedBy: indentation)
        let file = try context.createOutputFile(at: "sitemap.xml")
        try file.write(xml)
    }
}

private extension SiteMapGenerator where Site: MultiLanguageWebsite {
    func makeSiteMap(for sections: [Section<Site>], pages: [Page], site: Site) -> SiteMap {
        SiteMap(
            .forEach(sections) { section in
                guard !excludedPaths.contains(section.path) else {
                    return .empty
                }

                return .group(
                    .forEach(site.languages) { language in
                        .url(
                            .loc(site.url(for: context.section(section.id, in: language))),
                            .changefreq(.daily),
                            .priority(1.0),
                            .lastmod(max(
                                section.lastModified,
                                section.lastItemModificationDate ?? .distantPast
                            ))
                        )
                    },
                    .forEach(section.items) { item in
                        guard !excludedPaths.contains(item.path) else {
                            return .empty
                        }

                        return .url(
                            .loc(site.url(for: item)),
                            .changefreq(.monthly),
                            .priority(0.5),
                            .lastmod(item.lastModified)
                        )
                    }
                )
            },
            .forEach(pages) { page in
                guard !excludedPaths.contains(page.path) else {
                    return .empty
                }

                return .url(
                    .loc(site.url(for: page)),
                    .changefreq(.monthly),
                    .priority(0.5),
                    .lastmod(page.lastModified)
                )
            }
        )
    }
}
