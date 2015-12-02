<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="2.0"
  exclude-result-prefixes="xs">
  
  <xsl:template match="@* | *">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- @base-url is the original href from the HTML file. @href may already been hashed and turned into a file: URI by retrieving
    the resource -->
  
  <xsl:key name="file-entry-by-href" match="c:file" use="(@base-url, @href)[1]"/>
  
  <xsl:template match="html:img[key('file-entry-by-href', @src, collection()[2])/@error]">
    <xsl:element name="{if (ancestor::html:p) then 'span' else 'p'}" xmlns="http://www.w3.org/1999/xhtml">
      <xsl:attribute name="style" select="'display:inline-block; background-color:red; color:white; font-weight:bold;
        font-size:large padding:1em'"/>
      <xsl:attribute name="class" select="'error'"/>
      <xsl:attribute name="title" select="key('file-entry-by-href', @src, collection()[2])/@error"/>
      <xsl:value-of select="key('file-entry-by-href', @src, collection()[2])/@error"/>
    </xsl:element>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="  @src[matches(., '^https?:')]
                             [key('file-entry-by-href', ., collection()[2])] 
                       | @xlink:href[matches(., '^https?:')]
                                    [key('file-entry-by-href', ., collection()[2])]">
    <xsl:attribute name="{name()}" select="key('file-entry-by-href', ., collection()[2])/@name"/>
  </xsl:template>
  
</xsl:stylesheet>