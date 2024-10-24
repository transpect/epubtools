<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  exclude-result-prefixes="xs math"
  version="2.0">
  
  <xsl:template match="* | @*">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
    
  <xsl:template match="/">
    <xsl:variable name="unique-collection-uris" as="xs:string*"
                  select="distinct-values(collection()/base-uri())"/>
    <!-- filter Schematron collection if someone™ manages to pass 
         the same Schematron document multiple times to the input. -->
    <xsl:variable name="filtered-collection" as="document-node()*"
                  select="for $uri in ($unique-collection-uris) 
                          return collection()[base-uri() eq $uri][1]"/>
    <xsl:for-each select="$filtered-collection">
      <xsl:variable name="pos" select="position()" as="xs:integer"/>
      <xsl:result-document href="{base-uri()}.new">
        <xsl:apply-templates>
          <xsl:with-param name="more-specific-patterns" as="xs:string*" tunnel="yes" 
                          select="$filtered-collection[position() gt $pos]//*:pattern/@id"/>
        </xsl:apply-templates>
      </xsl:result-document>
    </xsl:for-each>
    <noout/>
  </xsl:template>
    
  <xsl:template match="*:pattern">
    <xsl:param name="more-specific-patterns" as="xs:string*" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$more-specific-patterns = (@id, @is-a)"/>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>
