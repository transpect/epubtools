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
  
  <xsl:variable name="magnification-divs" select="//div[@class eq 'magnification']" as="element()*"/>
  
  <!-- https://twitter.com/mkraetke/status/756463506829012992 -->
    
  <xsl:template match="body[.//div[@class eq 'magnification']]">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
    <xsl:message select="'&#xa;[info] insert Amazon Region Magnification markup to file: ', replace(base-uri(), '^.+/', '')"/>
  </xsl:template>
  
  <xsl:template match="div[@class eq 'magnification']">
    <xsl:variable name="index" select="index-of(for $i in $magnification-divs return generate-id($i), generate-id(.))" as="xs:integer"/>
    <xsl:variable name="id-base" select="(p[@id][1]/@id, concat('amzn-id-', $basename, '-', $index))[1]" as="xs:string"/>
    <div id="{concat($id-base, '-txt')}" class="source-mag">
      <a class="app-amzn-magnify" data-app-amzn-magnify="{concat('{&quot;targetId&quot;:&quot;', $id-base, '-magTarget&quot;,',
                                                                 '&quot;sourceId&quot;:&quot;' , $id-base, '-txt&quot;,',
                                                                 '&quot;ordinal&quot;:', $index, '}')}">
        <xsl:apply-templates/>
      </a>
    </div>
    <div id="{concat($id-base, '-magTarget')}" class="target-mag">
      <xsl:apply-templates mode="target-mag"/>
    </div>
    <xsl:result-document href="{replace(base-uri(), '\.x?html$', concat('-', $index, '.css'))}">
      <css xmlns="http://www.w3.org/1996/css" relative-name="{current-grouping-key()}" common="true">
        <xsl:value-of select="concat('#', $id-base, '-txt{position:absolute}&#xa;',
                                     '#', $id-base, '-magTarget{position:absolute}')"/>
      </css>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:template match="*" mode="target-mag">
    <xsl:copy>
      <xsl:apply-templates select="@* except @id, node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@*|*">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
