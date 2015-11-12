<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tr="http://transpect.io"
  version="2.0"
  exclude-result-prefixes="xs">
  
  <xsl:import href="../xsl/functions.xsl"/>
  
  <xsl:variable name="content-type" select="collection()[2]/c:body/@content-type" as="xs:string?"/>
  <xsl:variable name="fileext" select="tr:mime-type-to-fileext($content-type)" as="xs:string"/>
  <xsl:variable name="hash" select="if (/c:file/@query-hash eq '0') then '' else concat('_', /c:file/@query-hash)" as="xs:string"/>
  
  <xsl:template match="@* | *">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@media-type">
    <xsl:attribute name="{name()}" select="$content-type"/>
    <xsl:if test="collection()[2]/c:error or  not(matches($content-type, '^(image|audio|video)'))">
      <xsl:attribute name="error" select="(collection()[2]/c:error, 'content type is text')[1]"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@oebps-name | @target-filename | @name">
    <xsl:attribute name="{name()}">
      <xsl:analyze-string select="." regex="^(.+)(\.\w+)$">
        <xsl:matching-substring>
          <xsl:sequence select="concat(regex-group(1), $hash, regex-group(2))"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:sequence select="concat(., $hash, $fileext)"/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:attribute>
  </xsl:template>
  
</xsl:stylesheet>