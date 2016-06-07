<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:tr="http://transpect.io" 
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:epub="http://transpect.io/epubtools"
  version="1.0" 
  name="split-css"
  type="epub:split-css">
  
  <p:input port="source" sequence="true" primary="true">
    <p:documentation>
      Sequence of HTML chunks
    </p:documentation>
  </p:input>
  
  <p:input port="css-xml" primary="false">
    <p:documentation>
      CSS XML representation
    </p:documentation>
  </p:input>
  
  <p:output port="result" primary="true" sequence="true">
    <p:documentation>
      Each split HTML file, with an additional link to the individual CSS file if there are
      per-split CSS rules. Also, all of the newly generated CSS, with a base URI that matches the corresponding
      HTML file’s, except for the file extension.
    </p:documentation>
  </p:output>
  
  <p:output port="unused-css-resources" primary="false" sequence="true">
    <p:documentation>
      A css:css document containing XML representations of unused @font-face at rules.
    </p:documentation>
    <p:pipe port="unused-css-resources" step="per-split-css"/>
  </p:output>
  
  <p:option name="target" required="true"/>
  <p:option name="css-handling" required="true"/>
  <p:option name="basename" required="true"/>
  <p:option name="html-subdir-name" required="true"/>
  <p:option name="common-source-dir-elimination-regex" required="true"/>
  
  <p:option name="debug" select="'no'"/>
  <p:option name="debug-dir-uri" select="'debug'"/>
  
  <p:import href="http://transpect.io/css-tools/xpl/css-generate.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  
  <p:sink/>
  
  <p:choose name="per-split-css">
    <p:when test="contains($css-handling, 'regenerated-per-split')">
      <p:output port="result" primary="true" sequence="true">
        <p:pipe port="result" step="generate-css"/>
        <p:pipe port="secondary" step="insert-individual-css-link"/>
      </p:output>
      <p:output port="unused-css-resources" sequence="true">
        <p:pipe port="result" step="unused-css-resources"/>
      </p:output>
      
      <p:xslt name="per-split-css-xml-representations">
        <p:documentation>
          Primary output: the new, reduced common CSS. Secondary port: individual CSS files if
          applicable. Also on secondary port: A file named 'unused-css-resources.xml'
        </p:documentation>
        <p:input port="parameters">
          <p:empty/>
        </p:input>
        <p:input port="stylesheet">
          <p:document href="../xsl/per-split-css.xsl"/>
        </p:input>
        <p:input port="source">
          <p:pipe port="css-xml" step="split-css"/>
          <p:pipe port="source" step="split-css"/>
        </p:input>
        <p:with-param name="common-source-dir-elimination-regex" select="$common-source-dir-elimination-regex"/>
        <p:with-param name="html-subdir-name" select="$html-subdir-name"/>
        <p:with-param name="debug" select="$debug"/>
        <p:with-param name="final-pub-type" select="$target"/>
      </p:xslt>
      
      <p:sink/>
      
      <p:identity name="unused-css-resources">
        <p:input port="source" select="/*[ends-with(base-uri(/), 'unused-css-resources.xml')]">
          <p:pipe port="secondary" step="per-split-css-xml-representations"/>
        </p:input>
      </p:identity>
      
      <tr:store-debug>
        <p:with-option name="pipeline-step"
          select="concat('epubtools/html-splitter/', $basename, '/unused-css-resources')"/>
        <p:with-option name="active" select="$debug"/>
        <p:with-option name="base-uri" select="$debug-dir-uri"/>
      </tr:store-debug>
      
      <p:sink/>
      
      <p:identity name="individual-css-representations">
        <p:input port="source" select="/*[not(ends-with(base-uri(/), 'unused-css-resources.xml'))]">
          <p:pipe port="secondary" step="per-split-css-xml-representations"/>
        </p:input>
      </p:identity>
      
      <p:sink/>
      
      <p:xslt name="insert-individual-css-link" template-name="main">
        <p:documentation>
          Will insert links for per-split css. Has side effect: svg namespace fixup.
        </p:documentation>
        <p:input port="parameters">
          <p:empty/>
        </p:input>
        <p:input port="stylesheet">
          <p:document href="../xsl/insert-individual-css-link.xsl"/>
        </p:input>
        <p:input port="source">
          <p:pipe port="source" step="split-css"/>
          <p:pipe port="result" step="individual-css-representations"/>
        </p:input>
        <p:with-param name="html-subdir-name" select="$html-subdir-name"/>
        <p:with-param name="target" select="$target"/>
      </p:xslt>
      
      <p:for-each>
        <p:iteration-source>
          <p:pipe port="result" step="insert-individual-css-link"/>
          <p:pipe port="secondary" step="insert-individual-css-link"/>
        </p:iteration-source>
        <tr:store-debug>
          <p:with-option name="pipeline-step"
                         select="concat('epubtools/html-splitter/', $basename, '/individual-css-links/', replace(base-uri(), '^.+/', ''))"/>
          <p:with-option name="active" select="$debug"/>
          <p:with-option name="base-uri" select="$debug-dir-uri"/>
        </tr:store-debug>
      </p:for-each>
      
      <p:for-each name="generate-css">
        <p:iteration-source>
          <p:pipe port="result" step="per-split-css-xml-representations"/>
          <p:pipe port="result" step="individual-css-representations"/>
        </p:iteration-source>
        <p:output port="result" primary="true"/>
        
        <css:generate name="gen" prepend-resource-path="../">
          <p:with-option name="strip-comments"
                         select="if(contains($css-handling, 'remove-comments'))
                                 then 'true' 
                                 else 'false'"/>
        </css:generate>
        
        <tr:store-debug>
          <p:with-option name="pipeline-step"
                         select="concat('epubtools/html-splitter/', $basename, '/per-split-css/', replace(base-uri(), '^.+/', ''))"/>
          <p:with-option name="active" select="$debug"/>
          <p:with-option name="base-uri" select="$debug-dir-uri"/>
        </tr:store-debug>
        
      </p:for-each>
      
      <p:sink/>
      
    </p:when>
    
    <p:when test="$css-handling = 'unchanged'">
      <p:output port="result" primary="true"/>
      <p:output port="unused-css-resources" sequence="true">
        <p:empty/>
      </p:output>
      
      <p:identity>
        <p:input port="source">
          <p:pipe port="source" step="split-css"/>
        </p:input>
      </p:identity>
      
    </p:when>
    
    <p:otherwise>
      <p:documentation>regenerated</p:documentation>
      <p:output port="result" primary="true"/>
      <p:output port="unused-css-resources" sequence="true">
        <p:empty/>
      </p:output>
      
      <css:generate name="gen" prepend-resource-path="../">
        <p:input port="source">
          <p:pipe port="css-xml" step="split-css"/>
        </p:input>
      </css:generate>
      
      <p:sink/>
      
      <p:identity>
        <p:input port="source">
          <p:pipe port="source" step="split-css"/>
          <p:pipe port="result" step="gen"/>
        </p:input>
      </p:identity>
      
    </p:otherwise>
  </p:choose>
  
</p:declare-step>