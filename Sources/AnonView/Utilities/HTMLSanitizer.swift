import Foundation

private let htmlEntityReplacements: [String: String] = [
    "&amp;": "&",
    "&lt;": "<",
    "&gt;": ">",
    "&quot;": "\"",
    "&#039;": "'",
    "&#39;": "'",
    "&nbsp;": " ",
]

private let markdownSpecialCharacters = ["\\", "[", "]", "(", ")", "*", "_", "`", "~", ">", "#", "+", "-", "!", "|", "{", "}", "."]

extension String {
    var lightlyParsedHTML: String {
        let replacedBreaks = self
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")

        let strippedTags = replacedBreaks.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        return decodeHTMLEntities(in: strippedTags)
    }

    var commentMarkdown: String {
        let replacedBreaks = self
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")

        let anchorPattern = #"<a\b[^>]*href="([^"]+)"[^>]*>(.*?)</a>"#
        guard let regex = try? NSRegularExpression(pattern: anchorPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return replacedBreaks.lightlyParsedHTML
        }

        let nsString = replacedBreaks as NSString
        let matches = regex.matches(in: replacedBreaks, range: NSRange(location: 0, length: nsString.length))
        var transformed = replacedBreaks

        for match in matches.reversed() where match.numberOfRanges == 3 {
            let href = decodeHTMLEntities(in: nsString.substring(with: match.range(at: 1)))
            let linkText = nsString.substring(with: match.range(at: 2)).lightlyParsedHTML
            let destination = normalizedLinkDestination(for: href)
            let escapedText = escapeMarkdownText(linkText)
            let markdownLink = "[\(escapedText)](\(destination))"

            if let range = Range(match.range, in: transformed) {
                transformed.replaceSubrange(range, with: markdownLink)
            }
        }

        let strippedTags = transformed.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        return decodeHTMLEntities(in: strippedTags)
    }
}

private func normalizedLinkDestination(for href: String) -> String {
    let trimmed = href.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmed.hasPrefix("#p") {
        let postID = trimmed.dropFirst(2)
        return "anonview://post/\(postID)"
    }

    if trimmed.hasPrefix("//") {
        return "https:\(trimmed)"
    }

    if trimmed.hasPrefix("/") {
        return "https://boards.4chan.org\(trimmed)"
    }

    return trimmed
}

private func decodeHTMLEntities(in source: String) -> String {
    var decoded = source
    for (entity, value) in htmlEntityReplacements {
        decoded = decoded.replacingOccurrences(of: entity, with: value)
    }

    let numericPattern = #"&#([0-9]+);"#
    if let regex = try? NSRegularExpression(pattern: numericPattern) {
        let ns = decoded as NSString
        let matches = regex.matches(in: decoded, range: NSRange(location: 0, length: ns.length))
        for match in matches.reversed() where match.numberOfRanges == 2 {
            let codePointString = ns.substring(with: match.range(at: 1))
            if let codePoint = UInt32(codePointString),
               let scalar = UnicodeScalar(codePoint),
               let range = Range(match.range, in: decoded) {
                decoded.replaceSubrange(range, with: String(Character(scalar)))
            }
        }
    }

    return decoded
}

private func escapeMarkdownText(_ source: String) -> String {
    var escaped = source
    for special in markdownSpecialCharacters {
        escaped = escaped.replacingOccurrences(of: special, with: "\\\(special)")
    }
    return escaped
}
