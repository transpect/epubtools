<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="2.0" 
  exclude-result-prefixes="html">
  
  <xsl:param name="css-handling"/>
  
  <xsl:template match="* | @*">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>  
    </xsl:copy>
  </xsl:template>
  
  <!-- Strip style and elements and substitute with one stylesheet reference.
    Note: CSS is parsed with css-expand and written into a single stylesheet 
    generated with css-generate. -->
  
  <!--<xsl:template match="html:head/*[@type eq 'text/css']
                                  [. is (../*[@type eq 'text/css'])[1]]
                                  [not($css-handling = 'unchanged')]">
    <link href="styles/stylesheet.css" type="text/css" rel="stylesheet" />
  </xsl:template>-->
  
  <!--<xsl:template match="html:head/*[@type eq 'text/css']
                                  [not(. is (../*[@type eq 'text/css'])[1])]
                                  [not($css-handling = 'unchanged')]"/>-->
  
  <xsl:template match="@srcpath"/>

  <!-- Remove fixed attribute introduced by DTD parsing: -->
  <xsl:template match="/html:html/@version | /html:html/html:head/@profile"/>

</xsl:stylesheet>