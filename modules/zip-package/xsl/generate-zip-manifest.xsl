<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:tr="http://transpect.io"
  version="2.0">

  <xsl:param name="epubdir" required="yes"/>

  <xsl:template match="cx:document">
    
    <xsl:variable name="zip-manifest-entries" as="element(c:entry)+">
      <!-- process mimetype 1st -->
      <xsl:sequence select="tr:generate-manifest-entry(c:file[not(@error)][@oebps-name eq 'mimetype'], $epubdir)"/>
      <xsl:sequence select="tr:generate-manifest-entry(c:file[not(@error)][@oebps-name eq 'META-INF/container.xml'], $epubdir)"/>
      <xsl:if test="c:file[not(@error)][@oebps-name eq 'META-INF/encryption.xml']">
        <xsl:sequence select="tr:generate-manifest-entry(c:file[not(@error)][@oebps-name eq 'META-INF/encryption.xml'], $epubdir)"/>
      </xsl:if>
      <!-- order other entries by oebps-name -->
      <xsl:for-each select="c:file[not(@error)][normalize-space(@oebps-name)][not(@oebps-name = ('mimetype', 'META-INF/container.xml', 'META-INF/encryption.xml'))]">
        <xsl:sort select="upper-case(@oebps-name)" order="ascending"/>
        <xsl:sequence select="tr:generate-manifest-entry(., $epubdir)"/>
      </xsl:for-each>
    </xsl:variable>

    <c:zip-manifest>
      <xsl:sequence select="$zip-manifest-entries"/>
    </c:zip-manifest>
    
    <xsl:message
      select="concat('&#xa;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~&#xa;',
                     'COLLECT FILES FOR EPUB PACKAGE:&#xa;&#xa;',
                     string-join(for $i in $zip-manifest-entries return $i/@name, '&#xa;'),
                     '&#xa;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')"/>
    
  </xsl:template>
  
  <xsl:function name="tr:generate-manifest-entry" as="element(c:entry)">
    <xsl:param name="file" as="element(c:file)"/>
    <xsl:param name="epubdir" as="xs:string"/>
    <xsl:variable name="oebps-name" select="$file/@oebps-name" as="xs:string"/>
    <xsl:variable name="attr-href" select="concat($epubdir, 'epub/', $oebps-name)"/>
    <xsl:variable name="attr-method" select="if(matches($oebps-name, 'mimetype$')) then 'stored' else 'deflate'"/>
    <xsl:variable name="attr-level" select="if(matches($oebps-name, 'mimetype$')) then 'none' else 'smallest'"/>
    <c:entry name="{$oebps-name}" href="{$attr-href}" compression-method="{$attr-method}" compression-level="{$attr-level}"/>
  </xsl:function>

</xsl:stylesheet>
