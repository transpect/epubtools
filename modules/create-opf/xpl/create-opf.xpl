<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
  xmlns:epub="http://transpect.io/epubtools" 
  xmlns:tr="http://transpect.io"
  version="1.0"
  type="epub:create-opf" 
  name="create-opf">

  <p:documentation> This step expects a file list of the EPUB content files in this form:
            &lt;cx:document&gt;
                &lt;c:file name="OEBPS/chapter01.xhtml"/&gt;
            &lt;/cx:document&gt;
    It provides the OPF file on the result port. The output of the files port is the file reference of the content.opf but not
    all file references in the OPF file. </p:documentation>

  <p:input port="source">
    <p:documentation>A cx:document[c:file] document as produced by create-ops.xpl on the files port.</p:documentation>
  </p:input>
  <p:input port="meta">
    <p:documentation>/epub-config</p:documentation>
  </p:input>
  <p:output port="result" primary="true">
    <p:pipe port="result" step="generate-opf"/>
  </p:output>
  <p:output port="files" primary="false">
    <p:inline>
      <cx:document>
        <c:file oebps-name="OEBPS/content.opf" name="content.opf" media-type="application/oebps-package+xml"/>
      </cx:document>
    </p:inline>
  </p:output>

  <p:option name="base-uri" required="true" cx:type="xsd:anyURI"/>
  <p:option name="target" select="'EPUB2'" cx:type="xsd:string"/>
  <!-- EPUB2 | EPUB3 | MOBI | KF8 | FIXED-Apple -->
  <p:option name="terminate-on-error" select="'yes'"/>
  <p:option name="use-svg" select="'yes'"/> 
  <p:option name="create-a11y-meta" select="'yes'" cx:type="xsd:string" required="false"/>
  <p:option name="debug" select="'no'"/>
  <p:option name="debug-dir-uri" select="'debug'"/>
  
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  
  <p:variable name="layout" select="(/epub-config/@layout, 'reflowable')[1]" cx:type="xs:string">
    <p:pipe port="meta" step="create-opf"/>
  </p:variable>

  <p:variable name="html-subdir-name" select="(/epub-config/@html-subdir-name, '')[1]">
    <p:pipe port="meta" step="create-opf"/>
  </p:variable>
  
  <p:xslt name="generate-opf">
    <p:input port="source">
      <p:pipe port="meta" step="create-opf"/>
      <p:pipe port="source" step="create-opf"/>
    </p:input>
    <p:with-param name="target" select="$target"/>
    <p:with-param name="layout" select="$layout"/>
    <p:with-param name="terminate-on-error" select="$terminate-on-error"/>
    <p:with-param name="html-subdir-name" select="$html-subdir-name"/>
    <p:with-param name="create-a11y-meta" select="$create-a11y-meta"/>
    <p:input port="stylesheet">
      <p:document href="../xsl/create-opf.xsl"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="epubtools/create-opf/the-opf">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>
  
  <p:store indent="true" method="xml" omit-xml-declaration="false">
    <p:with-option name="href" select="concat(replace($base-uri, '^(.*[/])+(.*)', '$1'), 'epub/OEBPS/content.opf')"/>
  </p:store>

</p:declare-step>