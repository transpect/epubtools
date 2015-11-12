<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  version="2.0">

  <xsl:param name="epubdir" required="yes"/>

  <xsl:template match="cx:document">

    <xsl:variable name="fileref-elements" select="for $i in //c:file return $i/@oebps-name" as="item()+"/>

    <xsl:message
      select="concat('&#xa;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~&#xa;
COLLECT FILES FOR EPUB PACKAGE:&#xa;&#xa;',
string-join($fileref-elements, '&#xa;'),
'&#xa;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')"/>

    <c:zip-manifest>
      <xsl:for-each select="c:file[not(@error)]">
        <xsl:sort select="@oebps-name" order="descending"/>
        <xsl:variable name="attr-href" select="concat($epubdir, 'epub/', @oebps-name)"/>
        <xsl:variable name="attr-method" select="if(matches(@oebps-name, 'mimetype$')) then 'stored' else 'deflate'"/>
        <xsl:variable name="attr-level" select="if(matches(@oebps-name, 'mimetype$')) then 'none' else 'smallest'"/>
        <c:entry name="{@oebps-name}" href="{$attr-href}" compression-method="{$attr-method}"
          compression-level="{$attr-level}"/>
      </xsl:for-each>
    </c:zip-manifest>
  </xsl:template>

</xsl:stylesheet>
