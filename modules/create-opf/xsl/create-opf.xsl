<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:html="http://www.w3.org/1999/xhtml" 
  xmlns:epub="http://www.idpf.org/2007/ops"
  xmlns:opf="http://www.idpf.org/2007/opf" 
  xmlns:ncx="http://www.daisy.org/z3986/2005/ncx/"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns="http://www.idpf.org/2007/opf" 
  version="2.0" exclude-result-prefixes="c cx html xsi xs ncx">

  <xsl:param name="target" select="'EPUB2'"/>
  <xsl:param name="layout" select="'reflowable'"/>
  <xsl:param name="use-svg" select="'yes'"/>
  <xsl:param name="terminate-on-error" select="'yes'"/>
  <xsl:param name="html-subdir-name" as="xs:string"/>

  <xsl:template match="/">
    <package xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
      xmlns:opf="http://www.idpf.org/2007/opf"
      xmlns:dc="http://purl.org/dc/elements/1.1/" 
      xmlns:dcterms="http://purl.org/dc/terms/"
      xmlns="http://www.idpf.org/2007/opf" 
      version="{if($target = 'EPUB3') then '3.0' else '2.0'}"
      unique-identifier="bookid">
      
      <xsl:if test="$target eq 'EPUB3'">
        <xsl:attribute name="prefix" select="'rendition: http://www.idpf.org/vocab/rendition/#'"/>
      </xsl:if>
      
      <metadata>
        <xsl:if test="not(/epub-config/metadata/dc:identifier)">
          <xsl:message terminate="{$terminate-on-error}"
            select="concat('&#xa;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~&#xa;',
                           'ERROR: NO dc:identifier FOUND IN METADATA FILE.',
                           '&#xa;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~&#xa;')"/>
        </xsl:if>
        <xsl:variable name="identifiers" as="element(dc:identifier)*" select="/epub-config/metadata/dc:identifier"/>
        <xsl:for-each
          select="/epub-config/metadata/*[
                                not(
                                  self::meta[@property eq 'dcterms:modified'] or
                                  self::meta[@name eq 'cover']
                                )
                              ][
                                if (name() = 'dc:identifier')
                                then 
                                  if(exists(../dc:identifier/@format[. eq $target]))
                                  then @format = $target
                                  else not(@format)
                                else true()
                              ]">
          
          <xsl:if test="not($target eq 'EPUB3' and self::dc:date)">
            <xsl:element name="{name()}">
              <xsl:for-each select="@*[not(name(parent::*) eq 'dc:identifier')]">
                <!-- add meta/@property attributes -->
                <xsl:attribute name="{name()}" select="."/>
              </xsl:for-each>
              <xsl:if test="name() eq 'dc:identifier'">
                <xsl:choose>
                   <xsl:when test="@opf:scheme eq 'ORDER-NUMBER'">
                    <xsl:attribute name="id" select="'bookid'"/>
                    <xsl:attribute name="opf:scheme" select="@opf:scheme"/>
                  </xsl:when>
                  <xsl:when test="@opf:scheme ne 'ISBN'">
                    <xsl:if test="count($identifiers) eq 1">
                      <xsl:attribute name="id" select="'bookid'"/>
                    </xsl:if>
                    <xsl:attribute name="opf:scheme" select="@opf:scheme"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:attribute name="id" select="'bookid'"/>
                    <xsl:if test="@opf:scheme">
                      <xsl:attribute name="opf:scheme" select="@opf:scheme"/>
                    </xsl:if>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:if>
              <xsl:value-of select="."/>
            </xsl:element>
          </xsl:if>
        </xsl:for-each>
        <xsl:variable name="current-date-string" select="string(current-dateTime())" as="xs:string"/>
        <xsl:if test="$target = ('KF8', 'EPUB2')">
          <dc:date opf:event="modification">
            <xsl:value-of select="replace($current-date-string, '^(\d{4}-\d{2}-\d{2})T\d{2}:\d{2}:\d{2}\.(.*)$', '$1')"
            />
          </dc:date>
        </xsl:if>
        <xsl:if test="$target eq 'EPUB3'">
          <xsl:if test="not(/epub-config/metadata/meta/@property = 'dcterms:modified')">
            <meta property="dcterms:modified">
              <!-- e.g. 2011-01-01T12:00:00Z -->
              <!-- was something like: 2014-05-13T19:47:52.81+02:00 with this version
                      <xsl:value-of select="replace($current-date-string, '(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(\.\d{3}\+\d{2}:\d{2})', '$1Z')"/>
                       -->
              <xsl:value-of select="replace($current-date-string, '^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}).*$', '$1Z')"/>
            </meta>
          </xsl:if>
          <xsl:if test="not(/epub-config/metadata/meta/@property = 'rendition:layout')">
            <meta property="rendition:layout"><xsl:value-of select="if($layout eq 'fixed') 
                                                                    then 'pre-paginated' 
                                                                    else 'reflowable'"/></meta>
          </xsl:if>
          <xsl:if test="not(/epub-config/metadata/meta/@property = 'rendition:spread')">
            <meta property="rendition:spread"><xsl:value-of select="if($layout eq 'fixed') 
                                                                    then 'none' 
                                                                    else 'auto'"/></meta>
          </xsl:if>
          <xsl:if test="not(/epub-config/metadata/meta/@property = 'rendition:orientation')">
            <meta property="rendition:spread">auto</meta>
          </xsl:if>
          <xsl:if test="not(/epub-config/metadata/meta/@property = 'ibooks:specified-fonts')">
            <meta property="ibooks:specified-fonts">true</meta>
          </xsl:if>
        </xsl:if>
        <xsl:if test="collection()/epub-config/cover/@href ne ''">
          <!-- This fails to match the cover file id. Exclude it for EPUB3 since there are other mechanisms?
               Or fix it? -->
          <meta name="cover"
            content="{opf:normalize-id(
                              concat(
                                'idcover_', 
                                opf:id-from-filename(replace(collection()/epub-config/cover/@href, '^.+/', ''))
                              )
                            )}"
          />
        </xsl:if>
      </metadata>

      <manifest xmlns:opf="http://www.idpf.org/2007/opf">
        <xsl:for-each-group select="collection()//c:file[not($target = ('EPUB2', 'KF8') and matches(@name, 'nav\.xhtml'))]"
          group-by="@name">

          <xsl:variable name="strip-path" select="opf:strip-path(@name)"/>
          <xsl:variable name="id" select="opf:id-from-filename(@name)"/>
          <xsl:variable name="matching-media-overlay-id" 
            select="for $i in collection()//c:file[matches(@name, '\.smil$')]
                                                  [replace(@name, '\.smil$', '') = replace($strip-path, '\.x?html$', '')]
                    return opf:id-from-filename($i/@name)" as="xs:string*"/>

          <item href="{$strip-path}" media-type="{@media-type}" id="{opf:normalize-id($id)}">

            <xsl:variable name="properties" as="xs:string*">
              <xsl:if test="@nav eq 'true' or $strip-path eq 'nav.xhtml'">
                <xsl:value-of select="'nav'"/>
              </xsl:if>
              <xsl:if test="@svg eq 'true'">
                <xsl:value-of select="'svg'"/>
              </xsl:if>
              <xsl:if test="@mathml eq 'true'">
                <xsl:value-of select="'mathml'"/>
              </xsl:if>
              <xsl:if test="@script eq 'true' or @form eq 'true'">
                <xsl:value-of select="'scripted'"/>
              </xsl:if>
              <xsl:if test="@switch eq 'true'">
                <xsl:value-of select="'switch'"/>
              </xsl:if>
            </xsl:variable>
            <xsl:if test="$target eq 'EPUB3' and exists($properties) and not(matches($strip-path, '\.ncx$'))">
              <xsl:attribute name="properties" select="distinct-values($properties)" separator=" "/>
            </xsl:if>

            <xsl:if test="$target eq 'EPUB3' and matches($strip-path, '\.xpgt$')">
              <xsl:attribute name="fallback" select="'stylesheetcss'"/>
            </xsl:if>
            
            <xsl:if test="matches($strip-path, '\.x?html$') and exists($matching-media-overlay-id)">
              <xsl:attribute name="media-overlay" select="$matching-media-overlay-id"/>
            </xsl:if>

            <xsl:variable name="cover-nondir" as="xs:string?"
              select="if (collection()/epub-config/cover/@href) 
                      then replace(collection()/epub-config/cover/@href, '^.+/', '')
                      else ()"/>
            <xsl:if test="replace($strip-path, '^.+/', '') eq $cover-nondir">
              <!-- rewrite id attribute: same as in metadata/meta[@name eq 'cover']/@content-->
              <xsl:attribute name="id"
                select="opf:normalize-id(
                                  concat(
                                    'idcover_', 
                                    opf:id-from-filename($cover-nondir)
                                  )
                                )"/>
              <xsl:if test="$target eq 'EPUB3'">
                <xsl:attribute name="properties" select="'cover-image'"/>
              </xsl:if>
            </xsl:if>
          </item>

        </xsl:for-each-group>
      </manifest>

      <xsl:variable name="toc-type" as="xs:string" select="if($target eq 'EPUB3') then 'tocxhtml' else 'ncx'"/>

      <spine toc="ncx">
        <xsl:for-each
          select="collection()//c:file[matches(@name, '\.x?html$')]
                                                  [not(@spine = 'false')]
                                                  [not($target = ('EPUB2', 'KF8') and matches(@name, 'nav\.xhtml'))]">
          <xsl:sort select="number(@sequence)" data-type="number"/>
          <xsl:variable name="strip-path" select="replace(@name, 'OEBPS/', '')"/>
          <xsl:variable name="id" select="replace(replace($strip-path, '\.', ''),'/', '__')"/>
          <itemref idref="{opf:normalize-id($id)}">
            <xsl:if test="matches($strip-path, '_nolin\.xhtml$') or @linear = 'false'">
              <xsl:attribute name="linear" select="'no'"/>
            </xsl:if>
          </itemref>
        </xsl:for-each>
      </spine>
      <xsl:apply-templates select="collection()[$target = ('KF8', 'EPUB2')]/cx:document/html:html/html:body//html:nav[@epub:type = 'landmarks']"/>
    </package>
  </xsl:template>

  <xsl:template match="html:nav">
    <guide>
      <xsl:apply-templates select="html:ol/html:li/html:a/@epub:type"/>
    </guide>
  </xsl:template>

  <xsl:key name="type" match="type" use="@name"/>

  <xsl:template match="@epub:type[tokenize(., '\s+') = 'toc'][starts-with(../@href, '#')][not($target = 'EPUB2')]">
    <reference type="{.}" title="{..}">
      <xsl:attribute name="href" select="replace(base-uri(), '^.+/chunks/+', '')"/>
    </reference>
  </xsl:template>

  <xsl:template match="@epub:type[tokenize(., '\s+') = 'toc'][starts-with(../@href, '#')][$target = ('EPUB2', 'KF8')]">
    <!-- don’t link to generated HTML toc as it won’t be included in EPUB2 or mobi (KF8) -->
  </xsl:template>
  
  <xsl:template match="@epub:type">
    <xsl:variable name="context" select=".." as="element(html:a)"/>
    <xsl:for-each select="tokenize(., '\s+')">
      <xsl:variable name="guide-type" as="attribute(guide-type)?"
        select="key('type', ., collection()/epub-config)/@guide-type"/>
      <xsl:variable name="guide-types" as="xs:string*"
        select="if ($guide-type) then tokenize($guide-type, '\s+') else ."/>
      <xsl:for-each select="$guide-types">
        <reference type="{epub:guide-type(.)}" title="{$context}">
          <xsl:apply-templates select="$context/@href" mode="guide"/>
        </reference>
        <!-- add <reference type="text" title="Start" href="cover.xhtml"/> for mobi to open at cover -->
        <xsl:if test="matches(epub:guide-type(.), 'cover') and collection()/epub-config/cover/@display-in-mobi eq 'yes'">
          <reference type="text" title="Start">
            <xsl:apply-templates select="$context/@href" mode="guide"/>
          </reference>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="html:a/@href" mode="guide">
    <xsl:choose>
      <xsl:when test="matches(base-uri(), concat('/chunks/', $html-subdir-name, '/'))
                      or (normalize-space($html-subdir-name) 
                          and
                          (not(starts-with(., concat($html-subdir-name, '/'))))
                         )">
        <xsl:attribute name="href" select="concat($html-subdir-name, '/', .)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="epub:guide-type" as="xs:string?">
    <xsl:param name="type" as="xs:string"/>
    <xsl:choose>
      <xsl:when
        test="$type = ('acknowledgments', 'bibliography', 'colophon', 'copyright-page', 'cover', 'dedication', 'epigraph', 
                               'foreword', 'glossary',  'index', 'loi', 'lot', 'notes', 'preface', 'text', 'title-page', 'toc')">
        <xsl:sequence select="$type"/>
      </xsl:when>
      <xsl:when test="$type = ('titlepage', 'fulltitle')">
        <xsl:sequence select="'title-page'"/>
      </xsl:when>
      <xsl:when test="$type = 'bodymatter'">
        <xsl:sequence select="'text'"/>
      </xsl:when>
      <xsl:when test="starts-with($type, 'other.')">
        <xsl:sequence select="$type"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="concat('other.', replace($type, ':', '_'))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="opf:normalize-id" as="xs:string">
    <xsl:param name="input" as="xs:string"/>
    <xsl:sequence select="replace($input, '^(\I)', '_$1')"/>
  </xsl:function>

  <xsl:function name="opf:strip-path" as="xs:string">
    <xsl:param name="in" as="xs:string"/>
    <xsl:sequence select="replace($in, 'OEBPS/', '')"/>
  </xsl:function>

  <xsl:function name="opf:id-from-filename" as="xs:string">
    <xsl:param name="in" as="xs:string"/>
    <xsl:sequence
      select="if( matches($in, '\.ncx$') ) 
                          then 'ncx' 
                          else replace(replace(opf:strip-path($in), '\.', ''),'/', '__')"/>
  </xsl:function>

</xsl:stylesheet>