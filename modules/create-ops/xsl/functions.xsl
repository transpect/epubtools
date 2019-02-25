<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:cat="urn:oasis:names:tc:entity:xmlns:xml:catalog"
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
    
    <xsl:variable name="media-type" select="tr:fileref-to-mime-type($prelim/self::attribute(base-url))" as="xs:string"/>

    <xsl:variable name="potentially-relative" select="replace($prelim/self::attribute(base-url), $htmlroot-uri-regex, '')" as="xs:string"/>

    <xsl:attribute name="potentially-relative" select="$potentially-relative"/>
    <xsl:attribute name="htmlroot-uri-regex" select="$htmlroot-uri-regex"/>
    <xsl:variable name="file-basename" as="xs:string">
      <xsl:choose>
        <xsl:when test="matches($potentially-relative, '^(https?|file):')">
          <xsl:choose>
            <xsl:when test="matches($media-type, '^application/(vnd.ms-opentype|(x-)?(truetype-font|font-woff))$')">
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
  
</xsl:stylesheet>