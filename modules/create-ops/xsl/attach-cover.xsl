<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:epub="http://www.idpf.org/2007/ops"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns="http://www.w3.org/1999/xhtml" 
  version="2.0" 
  exclude-result-prefixes="#all">

  <xsl:param name="use-svg" as="xs:string" select="'yes'"/>
  <xsl:param name="target" as="xs:string" select="'EPUB2'"/>
  
  <xsl:variable name="image-info" select="collection()[3]/c:results" as="element()?"/>
  
  <xsl:template match="@*|node()" priority="-10">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="html:body[not(
                                   html:div[@id = 'epub-cover-image-container']
                                   | descendant::*[@epub:type = 'cover']
                                )]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="collection()/epub-config/cover">
        <xsl:variable name="width" as="xs:string?" select="$image-info/c:result[@name eq 'width']/@value"/>
        <xsl:variable name="height" as="xs:string?" select="$image-info/c:result[@name eq 'height']/@value"/>
        <xsl:message>attach-cover: width=<xsl:value-of select="$width"/>, height=<xsl:value-of select="$height"/></xsl:message>
        <xsl:choose>
          <xsl:when test="$use-svg = ('true', 'yes') and $width and $height">
            <xsl:variable name="w" select="xs:integer(number(replace($width, 'px$', '')))" as="xs:integer"/>
            <xsl:variable name="h" select="xs:integer(number(replace($height, 'px$', '')))" as="xs:integer"/>
            <div class="cover" srcpath="epub-cover" id="epub-cover-image-container" epub:type="cover">
              <xsl:if test="collection()/epub-config/types/type[@name = 'cover']/@heading">
                <xsl:attribute name="title" select="collection()/epub-config/types/type[@name = 'cover']/@heading"/>
              </xsl:if>
              <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="100%"
                height="100%" viewBox="0 0 {$w} {$h}" id="epub-cover-svg-container">
                <xsl:if test="$target = 'EPUB3'"><xsl:attribute name="aria-describedby" select="'cover-title-id'"/></xsl:if>
                <title id="cover-title-id"><xsl:value-of select="if (collection()/epub-config/cover[@alt[normalize-space()]]) 
                                             then collection()/epub-config/cover/@alt
                                             else concat ('Cover for ', (collection()/epub-config/dc:title[normalize-space()], 'EPUB')[1])"/>
                </title>
                <image xlink:href="{collection()/epub-config/cover/@href}" width="{$w}" height="{$h}"/>
              </svg>
            </div>
          </xsl:when>
          <xsl:when test="collection()/c:result/@error-status">
            <xsl:attribute name="id" select="'epub-cover-image-container'"/>
            <p class="error">Could not retrieve <a>
              <xsl:copy-of select="collection()/c:result/@href"/>
              <xsl:value-of select="collection()/c:result/@href"/>
            </a> (Status: <xsl:value-of select="collection()/c:result/@error-status"/>)</p>
          </xsl:when>
          <xsl:otherwise>
            <div class="cover" srcpath="epub-cover" epub:type="cover">
              <xsl:if test="collection()/epub-config/types/type[@name = 'cover']/@heading">
                <xsl:attribute name="title" select="collection()/epub-config/types/type[@name = 'cover']/@heading"/>
              </xsl:if>
              <xsl:attribute name="id" select="'epub-cover-image-container'"/>
              <img id="epub-cover-image" src="{collection()/epub-config/cover/@href}" role="doc-cover">
                <xsl:attribute name="alt" select="if (collection()/epub-config/cover[@alt[normalize-space()]]) 
                                                  then collection()/epub-config/cover/@alt
                                                  else 'epub-cover-image'"/>
              </img>
            </div>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
