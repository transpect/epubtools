<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs" 
  xpath-default-namespace="http://www.w3.org/1999/xhtml" 
  version="2.0">

  <xsl:param name="page-layout"/><!-- page | spread -->

  <xsl:variable name="viewport-width"  select="replace(/html/head/meta[@name eq 'viewport']/@content, '.+?width=(\d+).+?', '$1')" as="xs:string"/>
  <xsl:variable name="viewport-height" select="replace(/html/head/meta[@name eq 'viewport']/@content, '.+?height=(\d+).+?', '$1')" as="xs:string"/>
  <xsl:variable name="basename"  select="replace(base-uri(), '^.+/(.+)\.x?html$', '$1')" as="xs:string"/>

  <xsl:template match="body">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:text>&#xa;</xsl:text>
      <div class="region-container">
        <xsl:text>&#xa;</xsl:text>
        <a class="app-amzn-magnify" 
          data-app-amzn-magnify="{concat('{&quot;targetId&quot;:&quot;magTarget-', $basename, '&quot;,',
                                          '&quot;sourceId&quot;:&quot;magSource-', $basename, '&quot;,',
                                          '&quot;ordinal&quot;:1}')}">
          <xsl:text>&#xa;</xsl:text>
          <div id="{concat('magSource-', $basename)}">
            <xsl:text>&#xa;</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>&#xa;</xsl:text>
          </div>
        </a>
      </div>
      <xsl:text>&#xa;</xsl:text>
      <div id="{concat('magTarget-', $basename)}" class="target-mag"></div>
      <xsl:text>&#xa;</xsl:text>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@*|*">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
