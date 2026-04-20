import Testing
@testable import AnonView

@Test func lightlyParsedHTMLDecodesEntitiesAndStripsTags() {
    let raw = "Hello &gt; world &#039;quote&#039; <span>inline</span><br>line"
    #expect(raw.lightlyParsedHTML == "Hello > world 'quote' inline\nline")
}

@Test func commentMarkdownConvertsQuoteLinks() {
    let raw = #"Link: <a href="#p123">&gt;&gt;123</a>"#
    #expect(raw.commentMarkdown == "Link: [>>123](anonview://post/123)")
}
