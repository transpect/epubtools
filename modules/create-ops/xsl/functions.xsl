<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:cat="urn:oasis:names:tc:entity:xmlns:xml:catalog"
  xmlns:epub="http://www.idpf.org/2007/ops"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:tr="http://transpect.io"
  exclude-result-prefixes="cat html tr xs"
  version="2.0">
  
  <xsl:import href="http://transpect.io/xslt-util/mime-type/xsl/mime-type.xsl"/>
  <xsl:import href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>

  <xsl:param name="cat:missing-next-catalogs-warning" select="'no'"/>

  <!-- perform simple sort -->
  
  <xsl:function name="tr:sort" as="item()*">
    <xsl:param name="sequence" as="item()*"/>
    <xsl:for-each select="$sequence">
      <xsl:sort select="."/>
      <xsl:copy-of select="."/>
    </xsl:for-each>
  </xsl:function>
  
  <xsl:function name="tr:parse-url" as="attribute(*)*">
    <xsl:param name="fileref" as="xs:string"/>
    <xsl:param name="targetdir" as="xs:string?"/>
    <xsl:param name="htmlroot" as="document-node(element(html:html))"/>
    <xsl:variable name="prelim" as="attribute(*)+">
      <xsl:analyze-string select="$fileref" regex="^(.+?)\?(.+)$">
        <xsl:matching-substring>
          <xsl:attribute name="base-url" select="regex-group(1)"/>
          <xsl:attribute name="query-string" select="regex-group(2)"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:attribute name="base-url" select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <!-- §§§ To do: check whether the XSLT based resolver may be eliminated here 
      because I added a resolution p:viewport step for the parsed CSS in create-ops.xpl.
      Maybe we still need it here for the URIs in HTML files. Then we might want to 
      get rid again of the resolution p:viewport?
    -->
    <xsl:variable name="href" select="tr:resolve-uri($fileref)"/>
    <xsl:if test="matches($fileref, '^(file|https?):.*?$')">
      <xsl:attribute name="href" select="$href"/>
    </xsl:if>
    
    <xsl:variable name="htmlroot-uri-regex" as="xs:string" 
      select="replace(
                replace(
                  base-uri($htmlroot/*), 
                  '^(.+/)(.+)$', 
                  '$1'
                ),
                '/+',
                '/+'
              )"/>
    <xsl:if test="not(normalize-space($prelim/self::attribute(base-url)))">
      <xsl:message select="'Empty base-url attribute in epubtools/modules/create-ops/xsl/functions.xsl, tr:parse-url(). Attributes: ', $prelim"/>
    </xsl:if>
    <xsl:variable name="media-type" select="tr:fileref-to-mime-type($prelim/self::attribute(base-url))" as="xs:string?"/>

    <xsl:variable name="potentially-relative" select="replace($prelim/self::attribute(base-url), $htmlroot-uri-regex, '')" as="xs:string"/>

    <xsl:attribute name="potentially-relative" select="$potentially-relative"/>
    <xsl:attribute name="htmlroot-uri-regex" select="$htmlroot-uri-regex"/>
    <xsl:variable name="file-basename" as="xs:string">
      <xsl:choose>
        <xsl:when test="matches($potentially-relative, '^(https?|file):')">
          <xsl:choose>
            <xsl:when test="matches($media-type, '^(application/(vnd.ms-opentype|(x-)?(truetype-font|font-woff)))|font/(ttf|woff)$')">
              <xsl:sequence select="concat('fonts/', replace($potentially-relative, '^.+/', ''))"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="replace($potentially-relative, '^.+/', '')"/>    
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$potentially-relative"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:attribute name="media-type" select="$media-type"/>
    <xsl:attribute name="oebps-name" select="concat('OEBPS/', $file-basename)"/>
    <xsl:attribute name="name" select="$file-basename"/>
    <xsl:variable name="epub-local-path" as="xs:string"
      select="if (not(matches($fileref, '^(file|https?):')) and matches($fileref, '/'))
      then replace($fileref, '^(.+/)(.+)', '$1') 
      else ''"/>
    
<!--    <xsl:variable name="epub-local-path" as="xs:string"
      select="replace($fileref, '[^/]$', '') 
      "/>-->
    
    <xsl:attribute name="epub-local-path" select="$epub-local-path"/>
    <xsl:attribute name="target-dir" select="concat($targetdir, 'epub/OEBPS/', $epub-local-path)"/>
<!--    <xsl:attribute name="local-href" select="if (matches($href, '^file:/') or matches($epub-local-path, '/'))  
                                             then ($href, concat($targetdir, $file-basename))[1]
                                             else concat($targetdir, $epub-local-path, 'epub/', $file-basename)"/>-->
      <xsl:attribute name="local-href">
        <xsl:choose>
          <xsl:when test="matches($href, '^file:/')">
            <xsl:sequence select="$href"/>
          </xsl:when>
          <xsl:when test="$epub-local-path = ''">
            <!-- not sure whether all relative paths should be resolved to the base URI -->
            <xsl:sequence select="resolve-uri(concat($epub-local-path, $file-basename), base-uri($htmlroot/*))"/>
          </xsl:when>
          <xsl:when test=" matches($epub-local-path, '/')">
            <!-- doesn’t it make a difference whether the paths are relative or absolute? -->
            <xsl:sequence select="concat($targetdir, $file-basename)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="concat($targetdir, $epub-local-path, 'epub/', $file-basename)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    
    <xsl:attribute name="target-filename" select="concat($targetdir,  'epub/OEBPS/', $file-basename)"/>
    <xsl:sequence select="$prelim"/>
  </xsl:function>

  <xsl:function name="tr:resolve-uri" as="xs:string">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:sequence select="tr:resolve-uri-by-catalog($uri, document('http://this.transpect.io/xmlcatalog/catalog.xml'))"/>
  </xsl:function>
  
  <xsl:variable name="epub:aria-role-mapping" as="element(entry)+">
    <entry epub:type="abstract" aria-role="doc-abstract" applicable="section"/>
    <entry epub:type="acknowledgments" aria-role="doc-acknowledgments" applicable="section"/>
    <entry epub:type="afterword" aria-role="doc-afterword" applicable="section"/>
    <entry epub:type="answer" aria-role="" applicable=""/>
    <entry epub:type="answers" aria-role="" applicable=""/>
    <entry epub:type="appendix" aria-role="doc-appendix" applicable="section"/>
    <entry epub:type="assessment" aria-role="" applicable=""/>
    <entry epub:type="assessments" aria-role="" applicable=""/>
    <entry epub:type="backmatter" aria-role="" applicable=""/>
    <entry epub:type="balloon" aria-role="" applicable=""/>
    <entry epub:type="biblioentry" aria-role="" applicable=""/>
    <entry epub:type="bibliography" aria-role="doc-bibliography" applicable="section"/>
    <entry epub:type="biblioref" aria-role="doc-biblioref" applicable="a"/>
    <entry epub:type="bodymatter" aria-role="" applicable=""/>
    <entry epub:type="bridgehead" aria-role="" applicable=""/>
    <entry epub:type="case-study" aria-role="" applicable=""/>
    <entry epub:type="chapter" aria-role="doc-chapter" applicable="section"/>
    <entry epub:type="colophon" aria-role="doc-colophon" applicable="section"/>
    <entry epub:type="concluding-sentence" aria-role="" applicable=""/>
    <entry epub:type="conclusion" aria-role="doc-conclusion" applicable="section"/>
    <entry epub:type="contributors" aria-role="" applicable=""/>
    <entry epub:type="copyright-page" aria-role="" applicable=""/>
    <entry epub:type="cover" aria-role="doc-cover" applicable="img"/>
    <entry epub:type="covertitle" aria-role="" applicable=""/>
    <entry epub:type="credit" aria-role="doc-credit" applicable="section"/>
    <entry epub:type="credits" aria-role="doc-credits" applicable="section"/>
    <entry epub:type="dedication" aria-role="doc-dedication" applicable="section"/>
    <entry epub:type="division" aria-role="" applicable=""/>
    <entry epub:type="endnote" aria-role="" applicable="li"/>
    <entry epub:type="endnotes" aria-role="doc-endnotes" applicable="section"/>
    <entry epub:type="epigraph" aria-role="doc-epigraph" applicable=""/>
    <entry epub:type="epilogue" aria-role="doc-epilogue" applicable="section"/>
    <entry epub:type="errata" aria-role="doc-errata" applicable="section"/>
    <entry epub:type="No Equivalent" aria-role="doc-example" applicable="aside section"/>
    <entry epub:type="feedback" aria-role="" applicable=""/>
    <entry epub:type="figure" aria-role="" applicable=""/>
    <entry epub:type="fill-in-the-blank-problem" aria-role="" applicable=""/>
    <entry epub:type="footnote" aria-role="doc-footnote" applicable="aside footer header"/>
    <entry epub:type="footnotes" aria-role="doc-endnotes" applicable="section"/>
    <entry epub:type="foreword" aria-role="doc-foreword" applicable="section"/>
    <entry epub:type="frontmatter" aria-role="" applicable=""/>
    <entry epub:type="fulltitle" aria-role="" applicable=""/>
    <entry epub:type="general-problem" aria-role="" applicable=""/>
    <entry epub:type="glossary" aria-role="doc-glossary" applicable="section"/>
    <entry epub:type="glossterm" aria-role="" applicable=""/>
    <entry epub:type="glossdef" aria-role="" applicable=""/>
    <entry epub:type="glossref" aria-role="doc-glossref" applicable="a"/>
    <entry epub:type="halftitle" aria-role="" applicable=""/>
    <entry epub:type="halftitlepage" aria-role="" applicable=""/>
    <entry epub:type="imprint" aria-role="" applicable=""/>
    <entry epub:type="imprimatur" aria-role="" applicable=""/>
    <entry epub:type="index" aria-role="doc-index" applicable="nav section"/>
    <entry epub:type="index-headnotes" aria-role="" applicable=""/>
    <entry epub:type="index-legend" aria-role="" applicable=""/>
    <entry epub:type="index-group" aria-role="" applicable=""/>
    <entry epub:type="index-entry-list" aria-role="" applicable=""/>
    <entry epub:type="index-entry" aria-role="" applicable=""/>
    <entry epub:type="index-term" aria-role="" applicable=""/>
    <entry epub:type="index-editor-note" aria-role="" applicable=""/>
    <entry epub:type="index-locator" aria-role="" applicable=""/>
    <entry epub:type="index-locator-list" aria-role="" applicable=""/>
    <entry epub:type="index-locator-range" aria-role="" applicable=""/>
    <entry epub:type="index-xref-preferred" aria-role="" applicable=""/>
    <entry epub:type="index-xref-related" aria-role="" applicable=""/>
    <entry epub:type="index-term-category" aria-role="" applicable=""/>
    <entry epub:type="index-term-categories" aria-role="" applicable=""/>
    <entry epub:type="introduction" aria-role="doc-introduction" applicable="section"/>
    <entry epub:type="keyword" aria-role="" applicable=""/>
    <entry epub:type="keywords" aria-role="" applicable=""/>
    <entry epub:type="label" aria-role="" applicable=""/>
    <entry epub:type="landmarks" aria-role="" applicable="ol ul"/>
    <entry epub:type="learning-objective" aria-role="" applicable=""/>
    <entry epub:type="learning-objectives" aria-role="" applicable=""/>
    <entry epub:type="learning-outcome" aria-role="" applicable=""/>
    <entry epub:type="learning-outcomes" aria-role="" applicable=""/>
    <entry epub:type="learning-resource" aria-role="" applicable=""/>
    <entry epub:type="learning-resources" aria-role="" applicable=""/>
    <entry epub:type="learning-standard" aria-role="" applicable=""/>
    <entry epub:type="learning-standards" aria-role="" applicable=""/>
    <entry epub:type="list" aria-role="" applicable=""/>
    <entry epub:type="list-item" aria-role="" applicable=""/>
    <entry epub:type="loa" aria-role="" applicable=""/>
    <entry epub:type="loi" aria-role="" applicable=""/>
    <entry epub:type="lot" aria-role="" applicable=""/>
    <entry epub:type="lov" aria-role="" applicable=""/>
    <entry epub:type="match-problem" aria-role="" applicable=""/>
    <entry epub:type="multiple-choice-problem" aria-role="" applicable=""/>
    <entry epub:type="noteref" aria-role="doc-noteref" applicable="a"/>
    <entry epub:type="notice" aria-role="doc-notice" applicable="section"/>
    <entry epub:type="ordinal" aria-role="" applicable=""/>
    <entry epub:type="other-credits" aria-role="" applicable=""/>
    <entry epub:type="panel" aria-role="" applicable=""/>
    <entry epub:type="panel-group" aria-role="" applicable=""/>
    <entry epub:type="pagebreak" aria-role="doc-pagebreak" applicable="hr"/>
    <entry epub:type="page-list" aria-role="doc-pagelist" applicable="nav section"/>
    <entry epub:type="part" aria-role="doc-part" applicable="section"/>
    <entry epub:type="practice" aria-role="" applicable=""/>
    <entry epub:type="practices" aria-role="" applicable=""/>
    <entry epub:type="preamble" aria-role="" applicable=""/>
    <entry epub:type="preface" aria-role="doc-preface" applicable="section"/>
    <entry epub:type="prologue" aria-role="doc-prologue" applicable="section"/>
    <entry epub:type="pullquote" aria-role="doc-pullquote" applicable="aside section"/>
    <entry epub:type="question" aria-role="" applicable=""/>
    <entry epub:type="qna" aria-role="doc-qna" applicable="section"/>
    <entry epub:type="referrer" aria-role="doc-backlink" applicable="a"/>
    <entry epub:type="revision-history" aria-role="" applicable=""/>
    <entry epub:type="seriespage" aria-role="" applicable=""/>
    <entry epub:type="sound-area" aria-role="" applicable=""/>
    <entry epub:type="subchapter" aria-role="" applicable=""/>
    <entry epub:type="subtitle" aria-role="doc-subtitle" applicable="h1 h2 h3 h4 h5 h6"/>
    <entry epub:type="table" aria-role="" applicable=""/>
    <entry epub:type="table-row" aria-role="" applicable=""/>
    <entry epub:type="table-cell" aria-role="" applicable=""/>
    <entry epub:type="text-area" aria-role="" applicable=""/>
    <entry epub:type="tip" aria-role="doc-tip" applicable="aside"/>
    <entry epub:type="title" aria-role="" applicable=""/>
    <entry epub:type="titlepage" aria-role="" applicable=""/>
    <entry epub:type="toc" aria-role="doc-toc" applicable="nav section"/>
    <entry epub:type="toc-brief" aria-role="" applicable=""/>
    <entry epub:type="topic-sentence" aria-role="" applicable=""/>
    <entry epub:type="true-false-problem" aria-role="" applicable=""/>
    <entry epub:type="volume" aria-role="" applicable=""/>
  </xsl:variable>
  
  <xsl:variable name="epub:any-aria-role-applicable" as="xs:string"
                select="'a abbr address b bdi bdo blockquote br canvas cite code del dfn div em i img ins kbd mark output p pre q rp rt ruby s samp small span strong sub sup table tbody td tfoot thead th tr time u var wbr'"/>
  
  <xsl:function name="epub:type2aria" as="attribute(role)?">
    <xsl:param name="epub-type" as="attribute(epub:type)"/>
    <xsl:param name="parent" as="element()"/>
    <xsl:variable name="mapping" as="xs:string*"
                  select="$epub:aria-role-mapping[some $type in tokenize($epub-type, '\s+') satisfies $type eq @epub:type]
                                                 [   tokenize(@applicable, '\s') = $parent/local-name()
                                                  or tokenize($epub:any-aria-role-applicable, '\s') = $parent/local-name()]
                                                 [normalize-space(@aria-role)]
                                                 /@aria-role"/>
    <xsl:if test="exists($mapping)">
      <!-- several role attributes may exist comma separated but if a digital publishing role is mapped there 
           may only be one https://idpf.github.io/epub-guides/epub-aria-authoring/ (2.) +  fallback from ARIA 1.1 -->
      <xsl:attribute name="role" select="if (some $m in $mapping satisfies starts-with($m, 'doc-'))
                                         then ($mapping[starts-with(., 'doc-')][not(. = 'doc-appendix')], $mapping[. = 'doc-appendix'](:prefer more specific role :))[1]
                                         else $mapping[1]"/>
    </xsl:if>
  </xsl:function>
  
</xsl:stylesheet>
