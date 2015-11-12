<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns="http://www.w3.org/1999/xhtml" 
  version="2.0" 
  exclude-result-prefixes="#all">

  <!-- collection()[1]: parsed CSS,
       collection()[2]: filelist -->
  
  <xsl:template match="@*|*">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:key name="by-href" match="c:file" use="@base-url"/>

  <xsl:template match="css:resource/@src">
    <xsl:copy/>
    <xsl:if test="matches(., '^(file|https?):')">
      <xsl:attribute name="local-src" select="key('by-href', ., collection()[2])/@name"/>  
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>